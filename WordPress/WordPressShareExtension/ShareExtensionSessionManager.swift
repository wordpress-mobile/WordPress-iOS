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

    /// For the provided group ID:
    ///
    ///   1. Find the (not completed) post upload op (there should be one one)
    ///   2. Find all of the completed media upload ops
    ///   3. Append the media to the postContent property of the post upload op
    ///   4. Save the post upload op and return it
    ///
    /// - Parameter groupID: Group ID representing all of the media upload ops and post upload op
    /// - Returns: The updated RemotePost or nil
    fileprivate func appendMediaToPostForGroupID(_ groupID: String) -> RemotePost? {
        var remotePost: RemotePost?
        if let postUploadOp = fetchPostUploadOpForGroup(groupID),
            let mediaUploadOps = fetchMediaUploadOpsForGroup(groupID) {
            // TODO: finish this!
        }

        return remotePost
    }

    /// Update *all* upload ops associated with the provided group ID with a status.
    ///
    /// - Parameters:
    ///   - status: status to set
    ///   - groupID: group ID for a set of upload ops
    ///
    fileprivate func markAllUploadOperationsWith(_ status: UploadOperation.UploadStatus, for groupID: String) {
        // Mark the items as complete in the shared core data instance
        let predicate = NSPredicate(format: "(groupID == %@)", groupID)
        for uploadOp in coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate) {
            uploadOp.currentStatus = status
        }
        coreDataStack.saveContext()
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

    /// Fetch the upload op that represents a post for a given group ID.
    ///
    /// NOTE: There will only ever be one post associated with a group of upload ops.
    ///
    /// - Parameter groupID: group ID for a set of upload ops
    /// - Returns: UploadOperation or nil
    fileprivate func fetchPostUploadOpForGroup(_ groupID: String) -> UploadOperation? {
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(groupID == %@ AND isMedia == false)", backgroundSessionIdentifier)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)

        return uploadOp
    }

    /// Fetch the upload op that represents a post for a given URLSession taskIdentifier
    ///
    /// - Parameter taskIdentifier: the taskIdentifier from a URLSessionTask
    /// - Returns: UploadOperation or nil
    fileprivate func fetchSessionUploadOpForTask(taskIdentifier: Int) -> UploadOperation? {
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(backgroundSessionTaskID == %d AND backgroundSessionIdentifier == %@)", taskIdentifier, backgroundSessionIdentifier)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)

        return uploadOp
    }

    /// Fetch all of the media upload ops for the provided group id
    ///
    /// - Parameter groupID: group ID for a set of media upload ops
    /// - Returns: An array of UploadOperations or nil
    fileprivate func fetchMediaUploadOpsForGroup(_ groupID: String) -> [UploadOperation]? {
        var mediaUploadOps: [UploadOperation]
        let predicate = NSPredicate(format: "(groupID == %@ AND isMedia == true)", groupID)
        mediaUploadOps = coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate)

        return mediaUploadOps
    }

    /// Fetches the group ID for the provided session ID.
    ///
    /// - Parameter sessionID: the session ID
    /// - Returns: group ID or nil if session does not have an associated group
    fileprivate func fetchGroupID(for sessionID: String) -> String? {
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@)", sessionID)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)

        return uploadOp?.groupID
    }
}

// MARK: - URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionDelegate {

    // If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message,
    // the session delegate will receive this message to indicate that all messages previously enqueued for this
    // session have been delivered. At this time it is safe to invoke the previously stored completion handler,
    // or to begin any internal updates that will result in invoking the completion handler.
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let completionHandler = backgroundSessionCompletionBlock {
            backgroundSessionCompletionBlock = nil
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        DDLogInfo("Completed background uploading of all media for session \(session).")

        // TODO: Check to see if there is no media OR no post upload ops. In these cases, no need to try to do anything here.

        guard let groupID = fetchGroupID(for: self.backgroundSessionIdentifier), !groupID.isEmpty else {
            DDLogError("Unable to find the Group ID for session with ID \(self.backgroundSessionIdentifier).")
            return
        }

        guard let postUploadOp = appendMediaToPostForGroupID(groupID) else {
            DDLogError("Unable to append media to the post for Group ID \(groupID).")
            return
        }

        // TODO: POST the post!

        // TODO: Cleanup?
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

// MARK: - URLSessionTaskDelegate

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
            DDLogError("Background session task completed with error. Session:\(session) Task:\(task.debugDescription) Error:\(error).")
            uploadOp.currentStatus = .Error
            WPAppAnalytics.track(.shareExtensionError, error: error)
        } else {
            uploadOp.currentStatus = .Complete
            if let fileName = uploadOp.fileName {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: fileName)
            }
            DDLogInfo("Background session task completed. Session:\(session) Task:\(task.debugDescription).")
        }
        coreDataStack.saveContext()
    }
}

// MARK: - URLSessionDataDelegate

extension ShareExtensionSessionManager: URLSessionDataDelegate {

    // Tells the delegate that the data task has received some of the expected data.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        DDLogDebug("Received server response data for task:\(dataTask.debugDescription).")
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let response = object as? [String: AnyObject],
            let media = response["media"] as? [[String: AnyObject]],
            let mediaDict = media.first else {
                DDLogError("Error parsing server response data. Task:\(dataTask.debugDescription)")
                return
        }

        if let uploadOp = fetchSessionUploadOpForTask(taskIdentifier: dataTask.taskIdentifier) {
            if let remoteMediaID = mediaDict["ID"] as? NSNumber {
                uploadOp.remoteMediaID = remoteMediaID.int64Value
            }

            if let remoteMediaUrlString  = mediaDict["URL"] as? String, !remoteMediaUrlString.isEmpty {
                uploadOp.remoteURL = remoteMediaUrlString
            }
            coreDataStack.saveContext()
        }
    }
}
