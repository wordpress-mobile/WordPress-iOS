import Foundation

/// Manages URLSessions initiated by the share extension
///
@objc class ShareExtensionSessionManager: NSObject {

    /// MARK: - Public Properties

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
}

extension ShareExtensionSessionManager: URLSessionTaskDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DDLogInfo("Completed background media uploading for session \(session).")

        // Cleanup the media directory in the shared container just in case it still contains temp files
        ShareMediaFileManager.shared.purgeUploadDirectory()

        backgroundSessionCompletionBlock?()
    }
}
