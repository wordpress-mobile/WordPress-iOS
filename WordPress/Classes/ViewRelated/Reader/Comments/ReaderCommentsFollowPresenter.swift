import Foundation

/// Methods used by the Reader in the Follow Conversation flow to:
/// - subscribe to post comments
/// - subscribe to in-app notifications

@objc protocol ReaderCommentsFollowPresenterDelegate: AnyObject {
    func followConversationComplete(success: Bool, post: ReaderPost)
    func toggleNotificationComplete(success: Bool, post: ReaderPost)
}

class ReaderCommentsFollowPresenter: NSObject {

    // MARK: - Properties

    private let post: ReaderPost
    private weak var delegate: ReaderCommentsFollowPresenterDelegate?
    private unowned let presentingViewController: UIViewController
    private let followCommentsService: FollowCommentsService?

    // MARK: - Initialization

    @objc required init(post: ReaderPost,
                        delegate: ReaderCommentsFollowPresenterDelegate? = nil,
                        presentingViewController: UIViewController) {
        self.post = post
        self.delegate = delegate
        self.presentingViewController = presentingViewController
        followCommentsService = FollowCommentsService.createService(with: post)
    }

    // MARK: - Subscriptions

    /// Toggles the state of conversation subscription.
    /// When enabled, the user will receive emails and in-app notifications for new comments.
    ///
    @objc func handleFollowConversationButtonTapped() {
        trackFollowToggled()

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        let oldIsSubscribed = post.isSubscribedComments
        let newIsSubscribed = !oldIsSubscribed

        // Define success block
        let successBlock = { [weak self] (taskSucceeded: Bool) in
            guard taskSucceeded else {
                DispatchQueue.main.async {
                    generator.notificationOccurred(.error)
                    let noticeTitle = newIsSubscribed ? Messages.followFail : Messages.unfollowFail
                    self?.presentingViewController.displayNotice(title: noticeTitle)
                    self?.informDelegateFollowComplete(success: false)
                }
                return
            }

            DispatchQueue.main.async {
                generator.notificationOccurred(.success)
                self?.informDelegateFollowComplete(success: true)

                guard newIsSubscribed else {
                    let noticeTitle = newIsSubscribed ? Messages.followSuccess : Messages.unfollowSuccess
                    self?.presentingViewController.displayNotice(title: noticeTitle)
                    return
                }

                // Show notice with Undo option. Push Notifications are opt-out.
                self?.updateNotificationSettings(shouldEnableNotifications: true, canUndo: true)
            }
        }

        // Define failure block
        let failureBlock = { [weak self] (error: Error?) in
            DDLogError("Reader Comments: error toggling subscription status: \(String(describing: error))")

            DispatchQueue.main.async {
                generator.notificationOccurred(.error)
                let noticeTitle = newIsSubscribed ? Messages.subscribeFail : Messages.unsubscribeFail
                self?.presentingViewController.displayNotice(title: noticeTitle)
                self?.informDelegateFollowComplete(success: false)
            }
        }

        // Call the service to toggle the subscription status
        followCommentsService?.toggleSubscribed(oldIsSubscribed, success: successBlock, failure: failureBlock)
    }

    /// Toggles the state of comment subscription notifications.
    /// When enabled, the user will receive in-app notifications for new comments.
    ///
    /// - Parameter canUndo: Boolean. When true, this provides a way for the user to revert their actions.
    /// - Parameter completion: Block called as soon the view controller has been removed.
    ///
    @objc func handleNotificationsButtonTapped(canUndo: Bool, completion: ((Bool) -> Void)? = nil) {
        trackNotificationsToggled(isNotificationEnabled: !post.receivesCommentNotifications)

        let shouldEnableNotifications = !self.post.receivesCommentNotifications

        updateNotificationSettings(shouldEnableNotifications: shouldEnableNotifications, canUndo: canUndo, completion: completion)
    }

    // MARK: - Notification Sheet

    @objc func showNotificationSheet(sourceBarButtonItem: UIBarButtonItem?) {
        showBottomSheet(sourceBarButtonItem: sourceBarButtonItem)
    }

    func showNotificationSheet(sourceView: UIView?) {
        showBottomSheet(sourceView: sourceView)
    }

}

// MARK: - Private Extension

private extension ReaderCommentsFollowPresenter {

    private func updateNotificationSettings(shouldEnableNotifications: Bool, canUndo: Bool, completion: ((Bool) -> Void)? = nil) {
        let action: ReaderHelpers.PostSubscriptionAction = shouldEnableNotifications ? .enableNotification : .disableNotification

        followCommentsService?.toggleNotificationSettings(shouldEnableNotifications, success: { [weak self] in
            completion?(true)
            self?.informDelegateNotificationComplete(success: true)

            guard let self = self else {
                return
            }

            guard canUndo else {
                let title = ReaderHelpers.noticeTitle(forAction: action, success: true)
                self.presentingViewController.displayNotice(title: title)
                return
            }

            self.presentingViewController.displayActionableNotice(
                title: Messages.promptTitle,
                message: Messages.promptMessage,
                actionTitle: Messages.undoActionTitle,
                actionHandler: { (accepted: Bool) in
                self.handleNotificationsButtonTapped(canUndo: false)
            })
        }, failure: { [weak self] error in
            DDLogError("Reader Comments: error toggling notification status: \(String(describing: error)))")
            let title = ReaderHelpers.noticeTitle(forAction: action, success: false)
            self?.presentingViewController.displayNotice(title: title)
            completion?(false)
            self?.informDelegateNotificationComplete(success: false)
        })
    }

    func showBottomSheet(sourceView: UIView? = nil, sourceBarButtonItem: UIBarButtonItem? = nil) {
        let sheetViewController = ReaderCommentsNotificationSheetViewController(isNotificationEnabled: post.receivesCommentNotifications, delegate: self)
        let bottomSheet = BottomSheetViewController(childViewController: sheetViewController)
        bottomSheet.show(from: presentingViewController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem)
    }

    func informDelegateFollowComplete(success: Bool) {
        delegate?.followConversationComplete(success: success, post: post)
    }

    func informDelegateNotificationComplete(success: Bool) {
        delegate?.toggleNotificationComplete(success: success, post: post)
    }

    struct Messages {
        // Follow Conversation
        static let followSuccess = NSLocalizedString("Successfully followed conversation", comment: "The app successfully subscribed to the comments for the post")
        static let unfollowSuccess = NSLocalizedString("Successfully unfollowed conversation", comment: "The app successfully unsubscribed from the comments for the post")
        static let followFail = NSLocalizedString("Unable to follow conversation", comment: "The app failed to subscribe to the comments for the post")
        static let unfollowFail = NSLocalizedString("Failed to unfollow conversation", comment: "The app failed to unsubscribe from the comments for the post")

        // Subscribe to Comments
        static let subscribeFail = NSLocalizedString("Could not subscribe to comments", comment: "The app failed to subscribe to the comments for the post")
        static let unsubscribeFail = NSLocalizedString("Could not unsubscribe from comments", comment: "The app failed to unsubscribe from the comments for the post")

        // In-app notifications prompt
        static let promptTitle = NSLocalizedString("Following this conversation", comment: "The app successfully subscribed to the comments for the post")
        static let promptMessage = NSLocalizedString("You'll get notifications in the app", comment: "Message for the action with opt-out revert action.")
        static let undoActionTitle = NSLocalizedString("Undo", comment: "Button title. Reverts the previous notification operation")
    }

    // MARK: - Tracks

    func trackFollowToggled() {
        var properties = [String: Any]()
        let followAction: FollowAction = !post.isSubscribedComments ? .followed : .unfollowed
        properties[WPAppAnalyticsKeyFollowAction] = followAction.rawValue
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeySource] = sourceForTracks()
        WPAnalytics.trackReader(.readerToggleFollowConversation, properties: properties)
    }

    func trackNotificationsToggled(isNotificationEnabled: Bool) {
        var properties = [String: Any]()
        properties[AnalyticsKeys.notificationsEnabled] = isNotificationEnabled
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeySource] = sourceForTracks()
        WPAnalytics.trackReader(.readerToggleCommentNotifications, properties: properties)
    }

    func sourceForTracks() -> String {
        if presentingViewController is ReaderCommentsViewController {
            return AnalyticsSource.comments.description()
        }

        if presentingViewController is ReaderDetailViewController {
            return AnalyticsSource.postDetails.description()
        }

        return AnalyticsSource.unknown.description()
    }

    enum FollowAction: String {
        case followed
        case unfollowed
    }

    private struct AnalyticsKeys {
        static let notificationsEnabled = "notifications_enabled"
    }

    private enum AnalyticsSource: String {
        case comments
        case postDetails
        case unknown

        func description() -> String {
            switch self {
            case .comments:
                return "reader_threaded_comments"
            case .postDetails:
                return "reader_post_details_comments"
            case .unknown:
                return "unknown"
            }
        }
    }

}

// MARK: - ReaderCommentsNotificationSheetDelegate Methods

extension ReaderCommentsFollowPresenter: ReaderCommentsNotificationSheetDelegate {

    func didToggleNotificationSwitch(_ isOn: Bool, completion: @escaping (Bool) -> Void) {
        handleNotificationsButtonTapped(canUndo: false, completion: completion)
    }

    func didTapUnfollowConversation() {
        handleFollowConversationButtonTapped()
    }

}
