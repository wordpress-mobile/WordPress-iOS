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

    /// Clean up the session manager and end things gracefully (run the stored completion block, etc). Run
    /// this after all the session tasks are completed.
    ///
    fileprivate func cleanupSessionAndTerminate() {
        // Run the stored completetion block for the session
        if let completionHandler = backgroundSessionCompletionBlock {
            backgroundSessionCompletionBlock = nil
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        DDLogInfo("Completed processing post and media upload for session \(backgroundSessionIdentifier).")
    }

    /// Logs the error and updates the upload op's status with `Error`
    ///
    /// - Parameters:
    ///   - errorString: Error string to log
    ///   - uploadOpObjectIDs: Array of object IDs
    ///
    fileprivate func logError(_ errorString: String, uploadOpObjectIDs: [NSManagedObjectID]) {
        guard uploadOpObjectIDs.count > 0 else {
            return
        }
        DDLogError(errorString)
        for uploadOpObjectID in uploadOpObjectIDs {
            updateStatus(.error, forUploadOpWithObjectID: uploadOpObjectID)
        }
    }

    fileprivate func logError(_ errorString: String, uploadOpObjectIDs: NSManagedObjectID...) {
        logError(errorString, uploadOpObjectIDs: uploadOpObjectIDs)
    }

    /// Appends all of the remote media URLs to the post's content property.
    /// For the provided group ID:
    ///   1. Find the (not completed) post upload op (there should be one)
    ///   2. Find all of the completed media upload ops
    ///   3. Append the media to the postContent property of the post upload op
    ///   4. Save the post upload op and return it
    ///
    /// - Parameter groupID: Group ID representing all of the media upload ops and single post upload op
    /// - Returns: The updated post PostUploadOperation or nil
    ///
    fileprivate func combinePostAndMediaContent(for groupID: String) -> PostUploadOperation? {
        guard let postUploadOp = fetchPostUploadOp(for: groupID),
            let mediaUploadOps = fetchMediaUploadOps(for: groupID) else {
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
    fileprivate func uploadPost(with postUploadOp: PostUploadOperation) {
        let postUploadOpID = postUploadOp.objectID
        guard let oauth2Token = ShareExtensionService.retrieveShareExtensionToken() else {
            logError("Error creating post: OAuth token is not defined.", uploadOpObjectIDs: postUploadOpID)
            return
        }
        guard postUploadOp.siteID > 0 else {
            logError("Error creating post: site ID was missing.", uploadOpObjectIDs: postUploadOpID)
            return
        }

        let api = WordPressComRestApi(oAuthToken: oauth2Token,
                                      userAgent: nil,
                                      backgroundUploads: false,
                                      backgroundSessionIdentifier: backgroundSessionIdentifier,
                                      sharedContainerIdentifier: WPAppGroupName)
        let remote = PostServiceRemoteREST(wordPressComRestApi: api, siteID: NSNumber(value: postUploadOp.siteID))
        postUploadOp.currentStatus = .inProgress
        coreDataStack.saveContext()

        remote.createPost(postUploadOp.remotePost, success: { post in
            guard let post = post else {
                return
            }

            if let postID = post.postID {
                DDLogInfo("Post \(post.postID.stringValue) successfully uploaded to site \(post.siteID.stringValue)")
                postUploadOp.remotePostID = postID.int64Value
            }
            postUploadOp.currentStatus = .complete
            self.coreDataStack.saveContext()
            self.cleanupSessionAndTerminate()
        }, failure: { error in
            var errorString = "Error creating post"
            if let error = error as NSError? {
                errorString += ": \(error.localizedDescription)"
            }
            self.logError(errorString, uploadOpObjectIDs: postUploadOpID)
            self.cleanupSessionAndTerminate()
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
            DDLogError("Error setting \(status.stringValue) status for UploadOperation Object with ID: \(uploadOpObjectID) — could not fetch object.")
            return
        }
        uploadOp?.currentStatus = status
        coreDataStack.saveContext()
    }

    /// Updates the remote media URL and remote media ID on an upload op that corresponds with the provided
    /// file name. If a parameter is nil, that specific param will not be updated.
    ///
    /// Note: We are searching for the upload op using a filename because a given task ID can have
    /// multiple files associated with it.
    ///
    /// - Parameters:
    ///   - fileName: the fileName from a URLSessionTask
    ///   - remoteMediaID: remote media ID.
    ///   - remoteURL: remote media URL string.
    func updateMediaOperation(for fileName: String, remoteMediaID: Int64?, remoteURL: String?) {
        guard let mediaUploadOp = fetchMediaUploadOp(for: fileName) else {
            DDLogError("Error loading UploadOperation Object with File Name: \(fileName)")
            return
        }

        if let remoteMediaID = remoteMediaID {
            mediaUploadOp.remoteMediaID = remoteMediaID
        }
        mediaUploadOp.remoteURL = remoteURL
        coreDataStack.saveContext()
    }

    /// Fetch an upload op in the current that matches the provided filename
    ///
    /// - Parameter fileName: the name of the local (and remote) file associated with a upload op
    /// - Returns: MediaUploadOperation or nil
    ///
    func fetchMediaUploadOp(for fileName: String) -> MediaUploadOperation? {
        var uploadOp: MediaUploadOperation?
        let predicate = NSPredicate(format: "(fileName == %@ AND backgroundSessionIdentifier == %@)", fileName, backgroundSessionIdentifier)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: MediaUploadOperation.self, matching: predicate)

        return uploadOp
    }

    /// Fetch the upload op that represents a post for a given group ID.
    ///
    /// NOTE: There will only ever be one post associated with a group of upload ops.
    ///
    /// - Parameter groupID: group ID for a set of upload ops
    /// - Returns: post PostUploadOperation or nil
    ///
    func fetchPostUploadOp(for groupID: String) -> PostUploadOperation? {
        var uploadOp: PostUploadOperation?
        let predicate = NSPredicate(format: "(groupID == %@)", groupID)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: PostUploadOperation.self, matching: predicate)

        return uploadOp
    }

    /// Fetch the post and media upload ops for a given URLSession taskIdentifier.
    ///
    /// NOTE: Because the WP API allows us to upload multiple media files in a single request, there
    /// will most likely be multiple upload ops for a given task id.
    ///
    /// - Parameter taskIdentifier: the taskIdentifier from a URLSessionTask
    /// - Returns: An array of UploadOperations or nil
    ///
    func fetchSessionUploadOps(for taskIdentifier: Int) -> [UploadOperation]? {
        var uploadOps: [UploadOperation]?
        let predicate = NSPredicate(format: "(backgroundSessionTaskID == %d AND backgroundSessionIdentifier == %@)", taskIdentifier, backgroundSessionIdentifier)
        uploadOps = coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate)

        return uploadOps
    }

    /// Fetch all of the media upload ops for the provided group id
    ///
    /// - Parameter groupID: group ID for a set of media upload ops
    /// - Returns: An array of MediaUploadOperations or nil
    ///
    func fetchMediaUploadOps(for groupID: String) -> [MediaUploadOperation]? {
        var mediaUploadOps: [MediaUploadOperation]?
        let predicate = NSPredicate(format: "(groupID == %@)", groupID)
        mediaUploadOps = coreDataStack.managedContext.allObjects(ofType: MediaUploadOperation.self, matching: predicate)

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

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let groupID = fetchGroupID(for: self.backgroundSessionIdentifier), !groupID.isEmpty else {
            DDLogError("Unable to find the Group ID for session with ID \(self.backgroundSessionIdentifier).")
            return
        }
        guard let postUploadOp = combinePostAndMediaContent(for: groupID) else {
            DDLogError("Unable to append media to the post for Group ID \(groupID).")
            return
        }

        // Now the media is all uploaded, let's append it to the post and upload
        uploadPost(with: postUploadOp)
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            DDLogError("Background session invalidated by the system. Session:\(session) Error:\(error).")
            WPAppAnalytics.track(.shareExtensionError, error: error)
        } else {
            DDLogError("Background session explicitly invalidated by WPiOS. Session:\(session).")
        }
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        DDLogDebug("didSendBodyData [session:\(session) task:\(task.debugDescription) bytesSent:\(bytesSent) totalBytesSent:\(totalBytesSent) totalBytesExpectedToSend:\(totalBytesExpectedToSend)]")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let uploadOps = fetchSessionUploadOps(for: task.taskIdentifier) else {
            DDLogError("Background session tasks were not found in shared database. Session:\(session) Task:\(task.debugDescription).")
            return
        }

        if let error = error {
            logError("Background session task completed with error. Session:\(session) Task:\(task.debugDescription) Error:\(error).",
                uploadOpObjectIDs: uploadOps.map({ $0.objectID }))
            WPAppAnalytics.track(.shareExtensionError, error: error)
            return
        }

        uploadOps.forEach { uploadOp in
            if let mediaUploadOp = uploadOp as? MediaUploadOperation, let fileName = mediaUploadOp.fileName {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: fileName)
            }
            updateStatus(.complete, forUploadOpWithObjectID: uploadOp.objectID)
        }
        DDLogInfo("Background session task completed. Session:\(session) Task:\(task.debugDescription).")
    }
}

// MARK: - ShareExtensionSessionManager Extension: URLSessionDataDelegate

extension ShareExtensionSessionManager: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let response = object as? [String: AnyObject],
            let media = response["media"] as? [[String: AnyObject]] else {
                DDLogError("Error parsing server response data. Task:\(dataTask.debugDescription)")
                return
        }

        media.forEach { mediaDict in
            // We need the filename here because multiple media files can be bundled into a single task
            guard let remoteFilenameString  = mediaDict["file"] as? String, !remoteFilenameString.isEmpty else {
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
            updateMediaOperation(for: remoteFilenameString, remoteMediaID: mediaID, remoteURL: urlString)
        }
    }
}
