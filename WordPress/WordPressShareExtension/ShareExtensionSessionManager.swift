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

    fileprivate func markAllSessionUploadOperationsWith(_ status: UploadOperation.UploadStatus) {
        // Mark the items as complete in the shared core data instance
        let predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@)", backgroundSessionIdentifier)
        for uploadOp in coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate) {
            uploadOp.currentStatus = .Complete
        }
        coreDataStack.saveContext()
    }

    fileprivate func removeAllSessionTempFiles() {
        let predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@ AND isMedia == true)", backgroundSessionIdentifier)
        for uploadOp in coreDataStack.managedContext.allObjects(ofType: UploadOperation.self, matching: predicate) {
            if let fileName = uploadOp.fileName {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: fileName)
            }
        }
    }

    fileprivate func fetchSessionPost(with groupID: String) -> RemotePost? {
        var remotePost: RemotePost?
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@ AND isMedia == false)", backgroundSessionIdentifier)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)
        remotePost = uploadOp?.remotePost

        return remotePost
    }

    fileprivate func fetchSessionUploadOp(taskID: Int) -> UploadOperation? {
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(backgroundSessionTaskID == %d AND backgroundSessionIdentifier == %@)", taskID, backgroundSessionIdentifier)
        uploadOp = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)

        return uploadOp
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
        DDLogInfo("Completed background media uploading for session \(session).")
    }

    // Tells the URL session that the session has been invalidated. If you invalidate a session by calling its
    // finishTasksAndInvalidate() method, the session waits until after the final task in the session finishes or
    // fails before calling this delegate method. If you call the invalidateAndCancel() method, the session calls
    // this delegate method immediately.
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            DDLogError("Background session invalidated with error. Session:\(session) Error:\(error).")
        } else {
            DDLogError("Background session explicitly invalidated. Session:\(session).")
        }
        WPAppAnalytics.track(.shareExtensionError, error: error)
        markAllSessionUploadOperationsWith(.Error)
    }
}

// MARK: - URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionTaskDelegate {
    
    // Periodically informs the delegate of the progress of sending body content to the server.
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        DDLogInfo("didSendBodyData [session:\(session) task:\(task.debugDescription) bytesSent:\(bytesSent) totalBytesSent:\(totalBytesSent) totalBytesExpectedToSend:\(totalBytesExpectedToSend)]")
    }

    // Tells the delegate that the task finished transferring data. Server errors are not reported through the
    // error parameter. The only errors your delegate receives through the error parameter are client-side errors,
    // such as being unable to resolve the hostname or connect to the host.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DDLogError("Background session task completed with error. Session:\(session) Task:\(task.debugDescription) Error:\(error).")
            return
        }

        if let uploadOp = fetchSessionUploadOp(taskID: task.taskIdentifier) {
            uploadOp.currentStatus = .Complete
            coreDataStack.saveContext()

            // TODO: embed the media into the post content and then upload in another bg session
            // var remotePost = fetchSessionPost(with: uploadOp.groupID)

            if let fileName = uploadOp.fileName {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: fileName)
            }
        }

        DDLogInfo("Background session task completed. Session:\(session) Task:\(task.debugDescription).")
    }
}

// MARK: - URLSessionDataDelegate

extension ShareExtensionSessionManager: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        DDLogDebug("Received server response data for task:\(dataTask.debugDescription).")
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let response = object as? [String: AnyObject],
            let media = response["media"] as? [[String: AnyObject]],
            let mediaDict = media.first else {
                DDLogError("Error parsing server response data. Task:\(dataTask.debugDescription)")
                return
        }

        if let uploadOp = fetchSessionUploadOp(taskID: dataTask.taskIdentifier) {
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
