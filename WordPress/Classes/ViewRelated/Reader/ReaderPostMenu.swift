import Foundation
import UIKit
import SafariServices

struct ReaderPostMenu {
    let post: ReaderPost
    let topic: ReaderAbstractTopic?
    weak var button: UIButton?
    weak var viewController: UIViewController?
    var context = ContextManager.shared.mainContext

    func makeMenu() -> [UIMenuElement] {
        return [
            makePrimaryActions(),
            makeSecondaryActions(),
            shouldShowReportOrBlockMenu ? makeBlockOrReportActions() : nil
        ].compactMap { $0 }
    }

    private func makePrimaryActions() -> UIMenu {
        let menu = UIMenu(options: [.displayInline], children: [
            share, comment, like, bookmark, reblog
        ].compactMap { $0 })
        menu.preferredElementSize = .medium
        return menu
    }

    private func makeSecondaryActions() -> UIMenu {
        UIMenu(options: [.displayInline], children: [
            viewPostInBrowser,
            copyPostLink,
            makeBlogMenu(),
        ].compactMap { $0 })
    }

    private func makeBlogMenu() -> UIMenuElement {
        var actions: [UIAction] = [goToBlog]
        if let siteURL = post.blogURL.flatMap(URL.init) {
            actions.append(viewBlogInBrowser(siteURL: siteURL))
        }
        if post.isFollowing {
            if let siteID = post.siteID?.intValue {
                actions.append(manageNotifications(for: siteID))
            }
            actions += [ubsubscribe]
        } else {
            actions += [subscribe]
        }
        return UIMenu(title: post.blogNameForDisplay() ?? Strings.blogDetails, children: actions)
    }

    // MARK: Actions

    private var share: UIAction {
        UIAction(Strings.share, systemImage: "square.and.arrow.up") {
            guard let viewController else { return }
            ReaderShareAction().execute(with: post, context: context, anchor: button ?? viewController.view, vc: viewController)
            track(.share)
        }
    }

    private var bookmark: UIAction {
        let isBookmarked = post.isSavedForLater
        return UIAction(isBookmarked ? Strings.bookmarked : Strings.bookmark, systemImage: isBookmarked ? "bookmark.fill" : "bookmark") {
            guard let viewController else { return }
            ReaderSaveForLaterAction().execute(with: post, origin: .otherStream, viewController: viewController)
            track(isBookmarked ? .removeBookmark : .bookmark)
        }
    }

    private var reblog: UIAction {
        UIAction(Strings.reblog, systemImage: "arrow.2.squarepath") {
            guard let viewController else { return }
            ReaderSaveForLaterAction().execute(with: post, origin: .otherStream, viewController: viewController)
            track(.reblog)
        }
    }

    private var comment: UIAction? {
        guard post.isCommentsEnabled else { return nil }
        return UIAction(Strings.comment, systemImage: "message") {
            guard let viewController else { return }
            ReaderCommentAction().execute(post: post, origin: viewController, source: .postCard)
            track(.comment)
        }
    }

    private var like: UIAction? {
        guard post.isLikesEnabled else { return nil }
        let isLiked = post.isLiked
        return UIAction(isLiked ? Strings.liked : Strings.like, systemImage: isLiked ? "star.fill" : "star") {
            ReaderLikeAction().execute(with: post)
            track(isLiked ? .removeLike : .like)
        }
    }

    private var viewPostInBrowser: UIAction? {
        guard let postURL = post.permaLink.flatMap(URL.init) else { return nil }
        return UIAction(Strings.viewInBrowser, systemImage: "safari") {
            let safariVC = SFSafariViewController(url: postURL)
            viewController?.present(safariVC, animated: true)
            track(.viewPostInBrowser)
        }
    }

    private var copyPostLink: UIAction? {
        guard let postURL = post.permaLink.flatMap(URL.init) else { return nil }
        return UIAction(Strings.copyLink, systemImage: "link") {
            UIPasteboard.general.string = postURL.absoluteString
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            track(.copyPostLink)
        }
    }

    private var goToBlog: UIAction {
        UIAction(Strings.goToBlog, systemImage: "chevron.right") {
            guard let viewController else { return }
            ReaderHeaderAction().execute(post: post, origin: viewController)
            track(.goToBlog)
        }
    }

    private var subscribe: UIAction {
        UIAction(Strings.subscribe, systemImage: "plus.circle") {
            ReaderSubscriptionHelper().toggleSiteSubscription(forPost: post)
            track(.subscribe)
        }
    }

    private func viewBlogInBrowser(siteURL: URL) -> UIAction {
        return UIAction(Strings.viewInBrowser, systemImage: "safari") {
            let safariVC = SFSafariViewController(url: siteURL)
            viewController?.present(safariVC, animated: true)
            track(.viewBlogInBrowser)
        }
    }

    private var ubsubscribe: UIAction {
        UIAction(Strings.unsubscribe, systemImage: "minus.circle", attributes: [.destructive]) {
            ReaderSubscriptionHelper().toggleSiteSubscription(forPost: post)
            track(.unsubscribe)
        }
    }

    private func manageNotifications(for siteID: Int) -> UIAction {
        UIAction(Strings.manageNotifications, systemImage: "bell") {
            guard let viewController else { return }
            NotificationSiteSubscriptionViewController.show(forSiteID: siteID, sourceItem: button ?? viewController.view, from: viewController)
            track(.manageNotifications)
        }
    }

    // MARK: Block and Report

    private func makeBlockOrReportActions() -> UIMenu {
        UIMenu(title: Strings.blockOrReport, image: UIImage(systemName: "hand.raised"), options: [.destructive], children: [
            blockSite,
            post.isWPCom ? blockUser : nil,
            reportPost,
            reportUser,
        ].compactMap { $0 })
    }

    private var blockSite: UIAction {
        UIAction(Strings.blockSite, systemImage: "hand.raised", attributes: [.destructive]) {
            ReaderBlockingHelper().blockSite(forPost: post)
            track(.blockSite)
        }
    }

    private var blockUser: UIAction {
        UIAction(Strings.blockUser, systemImage: "hand.raised", attributes: [.destructive]) {
            ReaderBlockingHelper().blockUser(forPost: post)
            track(.blockUser)
        }
    }

    private var reportPost: UIAction {
        UIAction(Strings.reportPost, systemImage: "flag", attributes: [.destructive]) {
            guard let viewController else { return }
            ReaderReportPostAction().execute(with: post, context: context, origin: viewController)
            track(.reportPost)
        }
    }

    private var reportUser: UIAction {
        UIAction(Strings.reportUser, systemImage: "flag", attributes: [.destructive]) {
            guard let viewController else { return }
            ReaderReportPostAction().execute(with: post, target: .author, context: context, origin: viewController)
            track(.reportUser)
        }
    }

    private var shouldShowReportOrBlockMenu: Bool {
        guard let topic else {
            return false
        }
        return ReaderHelpers.isTopicTag(topic) ||
            ReaderHelpers.topicIsDiscover(topic) ||
            ReaderHelpers.topicIsFreshlyPressed(topic) ||
            ReaderHelpers.topicIsFollowing(topic)
    }

    // MARK: Helpers

    private func track(_ button: ReaderPostMenuAnalyticsButton) {
        WPAnalytics.track(.readerPostContextMenuButtonTapped, properties: [
            "button": button.rawValue
        ])
    }
}

private extension UIAction {
    convenience init(_ title: String, systemImage: String, attributes: UIMenuElement.Attributes = [], _ action: @escaping () -> Void) {
        self.init(title: title, image: UIImage(systemName: systemImage), attributes: attributes, handler: { _ in action() })
    }
}

private enum ReaderPostMenuAnalyticsButton: String {
    case share = "share"
    case bookmark = "bookmark"
    case removeBookmark = "remove_bookmark"
    case like = "like"
    case removeLike = "remove_like"
    case comment = "comment"
    case reblog = "reblog"
    case viewPostInBrowser = "view_in_browser"
    case copyPostLink = "copy_post_link"
    case goToBlog = "blog_open"
    case viewBlogInBrowser = "blog_view_in_browser"
    case subscribe = "blog_subscribe"
    case unsubscribe = "blog_unsubscribe"
    case manageNotifications = "blog_manage_notifications"
    case blockSite = "block_site"
    case blockUser = "block_user"
    case reportPost = "report_post"
    case reportUser = "report_user"
}

private enum Strings {
    static let share = NSLocalizedString("reader.postContextMenu.share", value: "Share", comment: "Context menu action")
    static let bookmark = NSLocalizedString("reader.postContextMenu.bookmark", value: "Bookmark", comment: "Context menu action")
    static let bookmarked = NSLocalizedString("reader.postContextMenu.bookmarked", value: "Bookmarked", comment: "Context menu action")
    static let reblog = NSLocalizedString("reader.postContextMenu.reblog", value: "Reblog", comment: "Context menu action")
    static let comment = NSLocalizedString("reader.postContextMenu.comment", value: "Comment", comment: "Context menu action")
    static let like = NSLocalizedString("reader.postContextMenu.like", value: "Like", comment: "Context menu action")
    static let liked = NSLocalizedString("reader.postContextMenu.liked", value: "Liked", comment: "Context menu action")
    static let viewInBrowser = NSLocalizedString("reader.postContextMenu.viewInBrowser", value: "View in Browser", comment: "Context menu action")
    static let copyLink = NSLocalizedString("reader.postContextMenu.copyLink", value: "Copy Link", comment: "Context menu action")
    static let blockOrReport = NSLocalizedString("reader.postContextMenu.blockOrReportMenu", value: "Block or Report", comment: "Context menu action")
    static let goToBlog = NSLocalizedString("reader.postContextMenu.showBlog", value: "Go to Blog", comment: "Context menu action")
    static let subscribe = NSLocalizedString("reader.postContextMenu.subscribeT", value: "Subscribe", comment: "Context menu action")
    static let unsubscribe = NSLocalizedString("reader.postContextMenu.unsubscribe", value: "Unsubscribe", comment: "Context menu action")
    static let manageNotifications = NSLocalizedString("reader.postContextMenu.manageNotifications", value: "Manage Notifications", comment: "Context menu action")
    static let blogDetails = NSLocalizedString("reader.postContextMenu.blogDetails", value: "Blog Details", comment: "Context menu action (placeholder value when blog name not available – should never happen)")
    static let blockSite = NSLocalizedString("reader.postContextMenu.blockSite", value: "Block Site", comment: "Context menu action")
    static let blockUser = NSLocalizedString("reader.postContextMenu.blockUser", value: "Block User", comment: "Context menu action")
    static let reportPost = NSLocalizedString("reader.postContextMenu.reportPost", value: "Report Post", comment: "Context menu action")
    static let reportUser = NSLocalizedString("reader.postContextMenu.reportUser", value: "Report User", comment: "Context menu action")
}
