import Foundation
import UIKit

struct AbstractPostMenuHelper {
    let post: AbstractPost

    init(_ post: AbstractPost) {
        self.post = post
    }

    /// Creates a menu for post actions
    ///
    /// - parameters:
    ///   - presentingView: The view presenting the menu
    ///   - delegate: The delegate that performs post actions
    func makeMenu(presentingView: UIView, delegate: InteractivePostViewDelegate) -> UIMenu {
        return UIMenu(title: "", options: .displayInline, children: [
            UIDeferredMenuElement.uncached { [weak presentingView, weak delegate] completion in
                guard let presentingView, let delegate else { return }
                completion(makeSections(presentingView: presentingView, delegate: delegate))
            }
        ])
    }

    private func makeSections() -> [AbstractPostButtonSection] {
        switch post {
        case let post as Post:
            return PostCardStatusViewModel(post: post).buttonSections
        case let page as Page:
            return PageMenuViewModel(page: page).buttonSections
        default:
            assertionFailure("Unsupported entity: \(post)")
            return []
        }
    }

    /// Creates post actions grouped into sections
    ///
    /// - parameters:
    ///   - presentingView: The view presenting the menu
    ///   - delegate: The delegate that performs post actions
    private func makeSections(presentingView: UIView, delegate: InteractivePostViewDelegate) -> [UIMenu] {
        return makeSections()
            .filter { !$0.buttons.isEmpty }
            .map { section in
                let actions = makeActions(for: section.buttons, presentingView: presentingView, delegate: delegate)
                let menu = UIMenu(title: "", options: .displayInline, children: actions)

                if let submenuButton = section.submenuButton {
                    return UIMenu(
                        title: submenuButton.title(for: post),
                        image: submenuButton.icon,
                        children: [menu]
                    )
                } else {
                    return menu
                }
            }
    }

    /// Creates post actions
    ///
    /// - parameters:
    ///   - buttons: The list of buttons to turn into post actions
    ///   - presentingView: The view presenting the menu
    ///   - delegate: The delegate that performs post actions
    private func makeActions(
        for buttons: [AbstractPostButton],
        presentingView: UIView,
        delegate: InteractivePostViewDelegate
    ) -> [UIAction] {
        return buttons.map { button in
            UIAction(title: button.title(for: post), image: button.icon, attributes: button.attributes ?? [], handler: { [weak presentingView, weak delegate] _ in
                guard let presentingView, let delegate else { return }
                button.performAction(for: post, view: presentingView, delegate: delegate)
            })
        }
    }
}

protocol AbstractPostMenuAction {
    var icon: UIImage? { get }
    var attributes: UIMenuElement.Attributes? { get }
    func title(for post: AbstractPost) -> String
    func performAction(for post: AbstractPost, view: UIView, delegate: InteractivePostViewDelegate)
}

extension AbstractPostButton: AbstractPostMenuAction {

    var icon: UIImage? {
        switch self {
        case .retry: return UIImage(systemName: "arrow.clockwise")
        case .view: return UIImage(systemName: "safari")
        case .publish: return UIImage(systemName: "globe")
        case .stats: return UIImage(systemName: "chart.bar.xaxis")
        case .duplicate: return UIImage(systemName: "doc.on.doc")
        case .moveToDraft: return UIImage(systemName: "pencil.line")
        case .trash: return UIImage(systemName: "trash")
        case .cancelAutoUpload: return UIImage(systemName: "xmark.icloud")
        case .share: return UIImage(systemName: "square.and.arrow.up")
        case .blaze: return UIImage(systemName: "flame")
        case .comments: return UIImage(systemName: "bubble")
        case .settings: return UIImage(systemName: "gearshape")
        case .setParent: return UIImage(systemName: "text.append")
        case .setHomepage: return UIImage(systemName: "house")
        case .setPostsPage: return UIImage(systemName: "text.word.spacing")
        case .setRegularPage: return UIImage(systemName: "arrow.uturn.backward")
        case .pageAttributes: return UIImage(systemName: "doc")
        }
    }

    var attributes: UIMenuElement.Attributes? {
        switch self {
        case .trash:
            return [UIMenuElement.Attributes.destructive]
        default:
            return nil
        }
    }

    func title(for post: AbstractPost) -> String {
        switch self {
        case .retry: return Strings.retry
        case .view: return Strings.view
        case .publish: return Strings.publish
        case .stats: return Strings.stats
        case .duplicate: return Strings.duplicate
        case .moveToDraft: return Strings.draft
        case .trash: return post.status == .trash ? Strings.delete : Strings.trash
        case .cancelAutoUpload: return Strings.cancelAutoUpload
        case .share: return Strings.share
        case .blaze: return Strings.blaze
        case .comments: return Strings.comments
        case .settings: return Strings.settings
        case .setParent: return Strings.setParent
        case .setHomepage: return Strings.setHomepage
        case .setPostsPage: return Strings.setPostsPage
        case .setRegularPage: return Strings.setRegularPage
        case .pageAttributes: return Strings.pageAttributes
        }
    }

    func performAction(for post: AbstractPost, view: UIView, delegate: InteractivePostViewDelegate) {
        switch self {
        case .retry:
            delegate.retry(post)
        case .view:
            delegate.view(post)
        case .publish:
            delegate.publish(post)
        case .stats:
            delegate.stats(for: post)
        case .duplicate:
            delegate.duplicate(post)
        case .moveToDraft:
            delegate.draft(post)
        case .trash:
            delegate.trash(post)
        case .cancelAutoUpload:
            delegate.cancelAutoUpload(post)
        case .share:
            delegate.share(post, fromView: view)
        case .blaze:
            delegate.blaze(post)
        case .comments:
            delegate.comments(post)
        case .settings:
            delegate.showSettings(for: post)
        case .setParent:
            delegate.setParent(for: post)
        case .setHomepage:
            delegate.setHomepage(for: post)
        case .setPostsPage:
            delegate.setPostsPage(for: post)
        case .setRegularPage:
            delegate.setRegularPage(for: post)
        case .pageAttributes:
            break
        }
    }

    private enum Strings {
        static let cancelAutoUpload = NSLocalizedString("posts.cancelUpload.actionTitle", value: "Cancel upload", comment: "Label for the Post List option that cancels automatic uploading of a post.")
        static let stats = NSLocalizedString("posts.stats.actionTitle", value: "Stats", comment: "Label for post stats option. Tapping displays statistics for a post.")
        static let comments = NSLocalizedString("posts.comments.actionTitle", value: "Comments", comment: "Label for post comments option. Tapping displays comments for a post.")
        static let settings = NSLocalizedString("posts.settings.actionTitle", value: "Settings", comment: "Label for post settings option. Tapping displays settings for a post.")
        static let duplicate = NSLocalizedString("posts.duplicate.actionTitle", value: "Duplicate", comment: "Label for post duplicate option. Tapping creates a copy of the post.")
        static let publish = NSLocalizedString("posts.publish.actionTitle", value: "Publish now", comment: "Label for an option that moves a publishes a post immediately")
        static let draft = NSLocalizedString("posts.draft.actionTitle", value: "Move to draft", comment: "Label for an option that moves a post to the draft folder")
        static let delete = NSLocalizedString("posts.delete.actionTitle", value: "Delete permanently", comment: "Label for the delete post option. Tapping permanently deletes a post.")
        static let trash = NSLocalizedString("posts.trash.actionTitle", value: "Move to trash", comment: "Label for a option that moves a post to the trash folder")
        static let view = NSLocalizedString("posts.view.actionTitle", value: "View", comment: "Label for the view post button. Tapping displays the post as it appears on the web.")
        static let retry = NSLocalizedString("posts.retry.actionTitle", value: "Retry", comment: "Retry uploading the post.")
        static let share = NSLocalizedString("posts.share.actionTitle", value: "Share", comment: "Share the post.")
        static let blaze = NSLocalizedString("posts.blaze.actionTitle", value: "Promote with Blaze", comment: "Promote the post with Blaze.")
        static let setParent = NSLocalizedString("posts.setParent.actionTitle", value: "Set parent", comment: "Set the parent page for the selected page.")
        static let setHomepage = NSLocalizedString("posts.setHomepage.actionTitle", value: "Set as homepage", comment: "Set the selected page as the homepage.")
        static let setPostsPage = NSLocalizedString("posts.setPostsPage.actionTitle", value: "Set as posts page", comment: "Set the selected page as a posts page.")
        static let setRegularPage = NSLocalizedString("posts.setRegularPage.actionTitle", value: "Set as regular page", comment: "Set the selected page as a regular page.")
        static let pageAttributes = NSLocalizedString("posts.pageAttributes.actionTitle", value: "Page attributes", comment: "Opens a submenu for page attributes.")
    }
}
