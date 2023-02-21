import Foundation

protocol ReaderSiteBlockingControllerDelegate: AnyObject {

    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, willBeginBlockingSiteOfPost post: ReaderPost)
    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, didBlockSiteOfPost post: ReaderPost)
    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, didFailToBlockSiteOfPost post: ReaderPost, error: Error?)

    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, willBeginBlockingPostAuthor post: ReaderPost)
    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, didFinishBlockingPostAuthor post: ReaderPost, result: Result<Void, Error> )
}

extension ReaderSiteBlockingControllerDelegate {

    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, willBeginBlockingSiteOfPost post: ReaderPost) {}
    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, didBlockSiteOfPost post: ReaderPost) {}
    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, didFailToBlockSiteOfPost post: ReaderPost, error: Error?) {}

    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, willBeginBlockingPostAuthor post: ReaderPost) {}
    func readerSiteBlockingController(_ controller: ReaderPostBlockingController, didFinishBlockingPostAuthor post: ReaderPost, result: Result<Void, Error> ) {}
}

final class ReaderPostBlockingController {

    // MARK: - Properties

    /// The delegate receives updates about the site being blocked.
    weak var delegate: ReaderSiteBlockingControllerDelegate?

    /// Flag indicating whether sites are currently being blocked.
    var isBlockingPosts: Bool {
        return !(ongoingSitesBlocking.isEmpty && ongoingUsersBlocking.isEmpty)
    }

    /// Collection of site ids currently being blocked.
    private var ongoingSitesBlocking = Set<NSNumber>()

    /// Collection of user ids currently being blocked.
    private var ongoingUsersBlocking = Set<NSNumber>()

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
        center.addObserver(
            self,
            selector: #selector(handleUserBlockingWillBegin(notification:)),
            name: .ReaderUserBlockingWillBegin,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleUserBlockingDidFinish(notification:)),
            name: .ReaderUserBlockingDidFinish,
            object: nil
        )
    }

    // MARK: -

    private func removeBlockedPosts(authorID: NSNumber) {
        let context = ContextManager.shared.mainContext
        let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.entityName())
        request.predicate = .init(format: "\(#keyPath(ReaderPost.authorID)) = %@", authorID)
        guard let result = try? context.fetch(request) else {
            return
        }
        for object in result {
            context.deleteObject(object)
        }
        try? context.save()
    }

    // MARK: - Handling Notifications

    @objc private func handleUserBlockingWillBegin(notification: Foundation.Notification) {
        guard let post = notification.userInfo?[ReaderNotificationKeys.post] as? ReaderPost,
              let authorID = post.authorID
        else {
            return
        }
        self.ongoingUsersBlocking.insert(authorID)
        self.delegate?.readerSiteBlockingController(self, willBeginBlockingPostAuthor: post)
    }

    @objc private func handleUserBlockingDidFinish(notification: Foundation.Notification) {
        guard let post = notification.userInfo?[ReaderNotificationKeys.post] as? ReaderPost,
              let result = notification.userInfo?[ReaderNotificationKeys.result] as? Result<Void, Error>,
              let authorID = post.authorID
        else {
            return
        }
        self.ongoingUsersBlocking.remove(authorID)
        self.removeBlockedPosts(authorID: authorID)
        self.delegate?.readerSiteBlockingController(self, didFinishBlockingPostAuthor: post, result: result)
    }

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
