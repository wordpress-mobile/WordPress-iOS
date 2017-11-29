import Foundation
import CoreData

/// Manages URLSessions initiated by the share extension
///
@objc class ShareExtensionSessionManager: NSObject {

    // MARK: - Public Properties

    typealias ShareExtensionBackgroundCompletionBlock = () -> Void
    @objc var backgroundSessionCompletionBlock: ShareExtensionBackgroundCompletionBlock?

    // MARK: - Private Properties

    fileprivate let backgroundSessionIdentifier: String
    fileprivate let appGroup: String
    fileprivate lazy var backgroundSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
        configuration.sharedContainerIdentifier = self.appGroup
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()

    /// Core Data stack for application extensions
    ///
    fileprivate lazy var coreDataStack = SharedCoreDataStack()

    // MARK: - Initializers

    @objc required init(appGroup: String, backgroundSessionIdentifier: String) {
        self.appGroup = appGroup
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
    }

    deinit {
        shutdown()
    }

    // MARK: - Public Funcntions

    /// Invalidates the background URLSession allowing any outstanding tasks to complete.
    ///
    @objc func shutdown() {
        backgroundSession.finishTasksAndInvalidate()
    }

    /// Cancels all outstanding tasks and invalidates the background URLSession.
    ///
    @objc func forceShutdown() {
        backgroundSession.invalidateAndCancel()
    }

    /// Starts up the background URLSession with the sharedContainerIdentifier (appGroup) and backgroundSessionIdentifier
    /// passed into init().
    ///
    @objc func startBackgroundSession() {
        DDLogInfo("Initializing background session: \(backgroundSession)")
    }

    // MARK: - Private Functions

    /// Logs the error and updates the upload op's status with `Error`
    ///
    /// - Parameters:
    ///   - uploadOpObjectID: Managed object ID for a given upload op
    ///   - errorString: Error string to log
    ///
    fileprivate func logError(errorString: String, forUploadOpWithObjectID uploadOpObjectID: NSManagedObjectID) {
        DDLogError(errorString)
        updateStatus(.Error, forUploadOpWithObjectID: uploadOpObjectID)
    }

    /// Nukes all media files associated with the current NSURLSession. *Be careful* with this one because
    /// some of the upload operations could still be in flight or errored out (which means you
    /// may want to retry another time).
    ///
    fileprivate func removeAllMediaFilesForCurrentSession() {
        let predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@ AND isMedia == true)", backgroundSessionIdentifier)
        for uploadOp in coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate) {
            if let fileName = uploadOp.fileName {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: fileName)
            }
        }
    }

    /// Appends all of the remote media URLs to the post's content poperty.
    /// For the provided group ID:
    ///   1. Find the (not completed) post upload op (there should be one one)
    ///   2. Find all of the completed media upload ops
    ///   3. Append the media to the postContent property of the post upload op
    ///   4. Save the post upload op and return it
    ///
    /// - Parameter groupID: Group ID representing all of the media upload ops and single post upload op
    /// - Returns: The updated post UploadOperation or nil
    ///
    fileprivate func combinePostAndMediaContentForGroupID(_ groupID: String) -> UploadOperation? {
        guard let postUploadOp = fetchPostUploadOpForGroup(groupID),
            let mediaUploadOps = fetchMediaUploadOpsForGroup(groupID) else {
                return nil
        }
        let remoteURLText = mediaUploadOps.flatMap({ $0.remoteURL }).map({ "".stringByPrependingMediaURL($0) }).joined()
        let content = postUploadOp.postContent ?? ""
        postUploadOp.postContent = content + remoteURLText
        coreDataStack.saveContext()

        return postUploadOp
    }

    /// Uploads a post to the server
    ///
    /// - Parameter postUploadOp: The UploadOperation that represents a post
    ///
    fileprivate func uploadPost(postUploadOp: UploadOperation) {
        let postUploadOpID = postUploadOp.objectID
        guard let oauth2Token = ShareExtensionService.retrieveShareExtensionToken() else {
            logError(errorString: "Error creating post: OAuth token is not defined.", forUploadOpWithObjectID: postUploadOpID)
            return
        }
        guard postUploadOp.siteID > 0 else {
            logError(errorString: "Error creating post: site ID was missing.", forUploadOpWithObjectID: postUploadOpID)
            return
        }

        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: false,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)
        let remote = PostServiceRemoteREST.init(wordPressComRestApi: api, siteID: NSNumber(value: postUploadOp.siteID))
        updateStatus(.Error, forUploadOpWithObjectID: postUploadOpID)

        remote.createPost(postUploadOp.remotePost, success: { post in
            if let post = post {
                DDLogInfo("Post \(post.postID.stringValue) sucessfully uploaded to site \(post.siteID.stringValue)")
                postUploadOp.remotePostID = post.postID.int64Value
            }
            self.updateStatus(.Complete, forUploadOpWithObjectID: postUploadOpID)
        }, failure: { error in
            var errorString = "Error creating post"
            if let error = error as NSError? {
                errorString += ": \(error.localizedDescription)"
            }
            self.logError(errorString: errorString, forUploadOpWithObjectID: postUploadOpID)
        })
    }
}

// MARK: - ShareExtensionSessionManager Extension: Persistence Helpers

private extension ShareExtensionSessionManager {

    /// Updates the status using the given uploadOp's ObjectID.
    ///
    /// - Parameters:
    ///   - status: New status
    ///   - uploadOpObjectID: Managed object ID for a given upload op
    ///
    func updateStatus(_ status: UploadOperation.UploadStatus, forUploadOpWithObjectID uploadOpObjectID: NSManagedObjectID) {
        var uploadOp: UploadOperation?
        do {
            uploadOp = try coreDataStack.managedContext.existingObject(with: uploadOpObjectID) as? UploadOperation
        } catch {
            DDLogError("Error setting \(status.stringValue()) status for UploadOperation Object with ID: \(uploadOpObjectID) — could not fetch object.")
            return
        }
        uploadOp?.currentStatus = status
        coreDataStack.saveContext()
    }

    /// Updates the remote media URL and remote media ID on an upload op that corresponds with the provided task
    /// identifier. If a parameter is nil, it will not be updated.
    ///
    /// - Parameters:
    ///   - taskIdentifier: the taskIdentifier from a URLSessionTask
    ///   - remoteMediaID: remote media ID. Can be nil.
    ///   - remoteURL: remote media URL string. Can be nil.
    func updateMediaOperationForTask(_ taskIdentifier: Int, remoteMediaID: Int64?, remoteURL: String?) {
        guard let uploadMediaOp = fetchSessionUploadOpForTask(taskIdentifier: taskIdentifier) else {
            DDLogError("Error loading UploadOperation Object with Task ID: \(taskIdentifier)")
            return
        }

        if let remoteID = remoteMediaID {
            uploadMediaOp.remoteMediaID = remoteID
        }
        if let remoteUrlString = remoteURL, !remoteUrlString.isEmpty {
            uploadMediaOp.remoteURL = remoteUrlString
        }
        coreDataStack.saveContext()
    }

    /// Update *all* upload ops associated with the provided group ID with a given status.
    ///
    /// - Parameters:
    ///   - status: status to set
    ///   - groupID: group ID for a set of upload ops
    ///
    func markAllUploadOperationsWith(_ status: UploadOperation.UploadStatus, for groupID: String) {
        // Mark the items as complete in the shared core data instance
        let predicate = NSPredicate(format: "(groupID == %@)", groupID)
        for uploadOp in coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate) {
            uploadOp.currentStatus = status
        }
        coreDataStack.saveContext()
    }

    /// Fetch the upload op that represents a post for a given group ID.
    ///
    /// NOTE: There will only ever be one post associated with a group of upload ops.
    ///
    /// - Parameter groupID: group ID for a set of upload ops
    /// - Returns: post UploadOperation or nil
    ///
    func fetchPostUploadOpForGroup(_ groupID: String) -> UploadOperation? {
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(groupID == %@ AND isMedia == false)", groupID)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)

        return uploadOp
    }

    /// Fetch the upload op that represents a post for a given URLSession taskIdentifier
    ///
    /// - Parameter taskIdentifier: the taskIdentifier from a URLSessionTask
    /// - Returns: UploadOperation or nil
    ///
    func fetchSessionUploadOpForTask(taskIdentifier: Int) -> UploadOperation? {
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(backgroundSessionTaskID == %d AND backgroundSessionIdentifier == %@)", taskIdentifier, backgroundSessionIdentifier)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)

        return uploadOp
    }

    /// Fetch all of the media upload ops for the provided group id
    ///
    /// - Parameter groupID: group ID for a set of media upload ops
    /// - Returns: An array of UploadOperations or nil
    ///
    func fetchMediaUploadOpsForGroup(_ groupID: String) -> [UploadOperation]? {
        var mediaUploadOps: [UploadOperation]
        let predicate = NSPredicate(format: "(groupID == %@ AND isMedia == true)", groupID)
        mediaUploadOps = coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate)

        return mediaUploadOps
    }

    /// Fetches the group ID for the provided session ID.
    ///
    /// - Parameter sessionID: the session ID
    /// - Returns: group ID or nil if session does not have an associated group
    ///
    func fetchGroupID(for sessionID: String) -> String? {
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@)", sessionID)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)

        return uploadOp?.groupID
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionDelegate {

    // If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message,
    // the session delegate will receive this message to indicate that all messages previously enqueued for this
    // session have been delivered. At this time it is safe to invoke the previously stored completion handler,
    // or to begin any internal updates that will result in invoking the completion handler.
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // TODO: Check to see if there is no media OR no post upload ops. In these cases, no need to try to do anything here.
        guard let groupID = fetchGroupID(for: self.backgroundSessionIdentifier), !groupID.isEmpty else {
            DDLogError("Unable to find the Group ID for session with ID \(self.backgroundSessionIdentifier).")
            return
        }

        guard let postUploadOp = combinePostAndMediaContentForGroupID(groupID) else {
            DDLogError("Unable to append media to the post for Group ID \(groupID).")
            return
        }

        uploadPost(postUploadOp: postUploadOp)
        if let completionHandler = backgroundSessionCompletionBlock {
            backgroundSessionCompletionBlock = nil
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        DDLogInfo("Completed processing post and media upload for session \(session).")
    }

    // Tells the delegate that the session has been invalidated.
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            DDLogError("Background session invalidated by the system with error. Session:\(session) Error:\(error).")
            WPAppAnalytics.track(.shareExtensionError, error: error)
        } else {
            DDLogError("Background session explicitly invalidated. Session:\(session).")
        }
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionTaskDelegate {
    
    // Periodically informs the delegate of the progress of sending body content to the server.
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        DDLogDebug("didSendBodyData [session:\(session) task:\(task.debugDescription) bytesSent:\(bytesSent) totalBytesSent:\(totalBytesSent) totalBytesExpectedToSend:\(totalBytesExpectedToSend)]")
    }

    // Tells the delegate that the task finished transferring data. Server errors are not reported through the
    // error parameter. The only errors your delegate receives through the error parameter are client-side errors,
    // such as being unable to resolve the hostname or connect to the host.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let uploadOp = fetchSessionUploadOpForTask(taskIdentifier: task.taskIdentifier) else {
            DDLogError("Background session task was not found in shared database. Session:\(session) Task:\(task.debugDescription).")
            return
        }

        if let error = error {
            logError(errorString: "Background session task completed with error. Session:\(session) Task:\(task.debugDescription) Error:\(error).", forUploadOpWithObjectID: uploadOp.objectID)
            WPAppAnalytics.track(.shareExtensionError, error: error)
            return
        }

        if let fileName = uploadOp.fileName {
            ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: fileName)
        }
        updateStatus(.Complete, forUploadOpWithObjectID: uploadOp.objectID)
        DDLogInfo("Background session task completed. Session:\(session) Task:\(task.debugDescription).")
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionDataDelegate

extension ShareExtensionSessionManager: URLSessionDataDelegate {

    // Tells the delegate that the data task has received some of the expected data.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let response = object as? [String: AnyObject],
            let media = response["media"] as? [[String: AnyObject]],
            let mediaDict = media.first else {
                DDLogError("Error parsing server response data. Task:\(dataTask.debugDescription)")
                return
        }

        var mediaID: Int64?
        var urlString: String?
        if let remoteMediaID = mediaDict["ID"] as? NSNumber {
            mediaID = remoteMediaID.int64Value
        }
        if let remoteMediaUrlString  = mediaDict["URL"] as? String, !remoteMediaUrlString.isEmpty {
            urlString = remoteMediaUrlString
        }
        updateMediaOperationForTask(dataTask.taskIdentifier, remoteMediaID: mediaID, remoteURL: urlString)
    }
}
