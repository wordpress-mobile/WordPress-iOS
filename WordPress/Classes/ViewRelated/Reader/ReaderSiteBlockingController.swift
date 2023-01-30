import Foundation

protocol ReaderSiteBlockingControllerDelegate: AnyObject {

    func readerSiteBlockingController(_ controller: ReaderSiteBlockingController, willBeginBlockingSiteOfPost post: ReaderPost)
    func readerSiteBlockingController(_ controller: ReaderSiteBlockingController, didBlockSiteOfPost post: ReaderPost)
    func readerSiteBlockingController(_ controller: ReaderSiteBlockingController, didFailToBlockSiteOfPost post: ReaderPost, error: Error?)
}

extension ReaderSiteBlockingControllerDelegate {

    func readerSiteBlockingController(_ controller: ReaderSiteBlockingController, willBeginBlockingSiteOfPost post: ReaderPost) {}
    func readerSiteBlockingController(_ controller: ReaderSiteBlockingController, didBlockSiteOfPost post: ReaderPost) {}
    func readerSiteBlockingController(_ controller: ReaderSiteBlockingController, didFailToBlockSiteOfPost post: ReaderPost, error: Error?) {}
}

final class ReaderSiteBlockingController {

    // MARK: - Properties

    /// The delegate receives updates about the site being blocked.
    weak var delegate: ReaderSiteBlockingControllerDelegate?

    /// Flag indicating whether sites are currently being blocked.
    var isBlockingSites: Bool {
        return !ongoingSitesBlocking.isEmpty
    }

    /// Collection of site ids currently being blocked.
    private var ongoingSitesBlocking = Set<NSNumber>()

    // MARK: - Init

    init() {
        self.observeSiteBlockingNotifications()
    }

    // MARK: - Observing Notifications

    private func observeSiteBlockingNotifications() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleSiteBlockingWillBeginNotification(_:)),
            name: .ReaderSiteBlockingWillBegin,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleBlockSiteNotification(_:)),
            name: .ReaderSiteBlocked,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleSiteBlockingFailed(_:)),
            name: .ReaderSiteBlockingFailed,
            object: nil
        )
    }

    // MARK: - Handling Notifications

    @objc private func handleSiteBlockingWillBeginNotification(_ notification: Foundation.Notification) {
        guard let post = notification.userInfo?[ReaderNotificationKeys.post] as? ReaderPost else {
            return
        }
        self.ongoingSitesBlocking.insert(post.siteID)
        self.delegate?.readerSiteBlockingController(self, willBeginBlockingSiteOfPost: post)
    }

    @objc private func handleBlockSiteNotification(_ notification: Foundation.Notification) {
        guard let post = notification.userInfo?[ReaderNotificationKeys.post] as? ReaderPost else {
            return
        }
        self.ongoingSitesBlocking.remove(post.siteID)
        self.delegate?.readerSiteBlockingController(self, didBlockSiteOfPost: post)
    }

    @objc private func handleSiteBlockingFailed(_ notification: Foundation.Notification) {
        guard let post = notification.userInfo?[ReaderNotificationKeys.post] as? ReaderPost else {
            return
        }
        let error = notification.userInfo?[ReaderNotificationKeys.error] as? Error
        self.ongoingSitesBlocking.remove(post.siteID)
        self.delegate?.readerSiteBlockingController(self, didFailToBlockSiteOfPost: post, error: error)
    }
}
