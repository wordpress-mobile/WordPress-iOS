import UIKit

struct PostNoticeViewModel {
    let post: AbstractPost

    /// Returns the Notice represented by this view model.
    ///
    var notice: Notice {
        let action = self.action

        return Notice(title: title,
                      message: message,
                      feedbackType: .success,
                      actionTitle: action.title,
                      actionHandler: {
                        switch action {
                        case .publish:
                            self.publishPost()
                        case .view:
                            self.viewPost()
                        }
        })
    }

    // MARK: - Display values for Notice

    private var title: String {
        if let page = post as? Page {
            return title(for: page)
        } else {
            return title(for: post)
        }
    }

    private func title(for page: Page) -> String {
        let status = page.status ?? .publish

        switch status {
        case .draft:
            return NSLocalizedString("Page draft uploaded", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
        case .scheduled:
            return NSLocalizedString("Page scheduled", comment: "Title of notification displayed when a page has been successfully scheduled.")
        case .pending:
            return NSLocalizedString("Page pending review", comment: "Title of notification displayed when a page has been successfully saved as a draft.")
        default:
            return NSLocalizedString("Page published", comment: "Title of notification displayed when a page has been successfully published.")
        }
    }

    private func title(for post: AbstractPost) -> String {
        let status = post.status ?? .publish

        switch status {
        case .draft:
            return NSLocalizedString("Post draft uploaded", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
        case .scheduled:
            return NSLocalizedString("Post scheduled", comment: "Title of notification displayed when a post has been successfully scheduled.")
        case .pending:
            return NSLocalizedString("Post pending review", comment: "Title of notification displayed when a post has been successfully saved as a draft.")
        default:
            return NSLocalizedString("Post published", comment: "Title of notification displayed when a post has been successfully published.")
        }
    }

    private var message: String {
        let title = post.postTitle ?? ""
        if title.count > 0 {
            return title
        }

        return post.blog.displayURL as String? ?? ""
    }

    private enum Action {
        case publish
        case view

        var title: String {
            switch self {
            case .publish:
                return NSLocalizedString("Publish", comment: "Button title. Publishes a post.")
            case .view:
                return NSLocalizedString("View", comment: "Button title. Displays a summary / sharing screen for a specific post.")
            }
        }
    }

    private var action: Action {
        return (post.status == .draft) ? .publish : .view
    }

    // MARK: - Actions

    private func viewPost() {
        if post is Page {
            presentViewPage()
        } else {
            presentPostPost()
        }
    }

    private func presentViewPage() {
        guard let presenter = UIApplication.shared.delegate?.window??.topmostPresentedViewController,
            let post = postInContext else {
                return
        }

        let controller = PostPreviewViewController(post: post)
        controller.navigationItem.title = NSLocalizedString("View", comment: "Verb. The screen title shown when viewing a post inside the app.")
        controller.hidesBottomBarWhenPushed = true

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .formSheet
        presenter.present(navigationController, animated: true, completion: nil)
    }

    private func presentPostPost() {
        guard let presenter = UIApplication.shared.delegate?.window??.topmostPresentedViewController,
            let post = postInContext else {
                return
        }

        let editor = EditPostViewController(post: post as! Post)
        editor.modalPresentationStyle = .fullScreen
        editor.openWithPostPost = true
        editor.onClose = { _ in
        }
        presenter.present(editor, animated: true, completion: nil)
    }

    private func publishPost() {
        guard let post = postInContext else {
            return
        }

        post.status = .publish
        PostCoordinator.shared.save(post: post)
    }

    private var postInContext: AbstractPost? {
        let context = ContextManager.sharedInstance().mainContext
        let objectInContext = try? context.existingObject(with: post.objectID)
        let postInContext = objectInContext as? AbstractPost

        return postInContext
    }
}
