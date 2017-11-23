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

    required init(appGroup: String, backgroundSessionIdentifier: String) {
        self.appGroup = appGroup
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
    }

    deinit {
        shutdown()
    }

    // MARK: - Public Funcntions

    /// Invalidates the background URLSession allowing any outstanding tasks to complete.
    ///
    func shutdown() {
        backgroundSession.finishTasksAndInvalidate()
    }

    /// Cancels all outstanding tasks and invalidates the background URLSession.
    ///
    func forceShutdown() {
        backgroundSession.invalidateAndCancel()
    }

    /// Starts up the background URLSession with the sharedContainerIdentifier (appGroup) and backgroundSessionIdentifier
    /// passed into init().
    ///
    func startBackgroundSession() {
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

    fileprivate func fetchSessionPost() -> RemotePost? {
        var remotePost: RemotePost?
        var uploadOp: UploadOperation?
        let predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@ AND isMedia == false)", backgroundSessionIdentifier)
        let uploadOp? = coreDataStack.managedContext.firstObject(ofType: UploadOperation.self, matching: predicate)
        remotePost = uploadOp?.remotePost

        return remotePost
    }
}

// MARK: - URLSessionTaskDelegate

extension ShareExtensionSessionManager: URLSessionTaskDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DDLogInfo("Completed background media uploading for session \(session).")
        removeAllSessionTempFiles()
        markAllSessionUploadOperationsWith(.Complete)
        backgroundSessionCompletionBlock?()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error as NSError? else {
            return
        }
        WPAppAnalytics.track(.shareExtensionError, error: error)
        markAllSessionUploadOperationsWith(.Error)
        DDLogError("Error recieved for share extension media uploading. Session:\(session) Task:\(task) Error:\(error).")
    }
}
