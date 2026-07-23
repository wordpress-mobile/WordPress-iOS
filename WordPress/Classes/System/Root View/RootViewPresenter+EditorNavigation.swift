import Foundation
import WordPressData

extension RootViewPresenter {
    func currentOrLastBlog() -> Blog? {
        if let blog = currentlyVisibleBlog() {
            return blog
        }
        let context = ContextManager.shared.mainContext
        return Blog.lastUsedOrFirst(in: context)
    }

    func showNewPostEditor(
        blog: Blog? = nil,
        context: NewPostEditorContext = .init(
            analytics: .editorCreatedPost(source: "create_button", postType: "post")
        )
    ) {
        if rootViewController.presentedViewController != nil {
            rootViewController.dismiss(animated: false)
        }
        guard let blog = blog ?? currentOrLastBlog() else { return }
        MainActor.assumeIsolated {
            PostEditorRouter.showNewPost(for: blog, from: rootViewController, context: context)
        }
    }

    func showPostEditor(
        post: Post,
        animated: Bool = true,
        completion afterDismiss: (() -> Void)? = nil
    ) {
        if rootViewController.presentedViewController != nil {
            rootViewController.dismiss(animated: false)
        }
        let editor = EditPostViewController(post: post)
        editor.showImmediately = !animated
        editor.afterDismiss = afterDismiss
        rootViewController.present(editor, animated: false)
    }

    func showNewPageEditor(
        blog: Blog? = nil,
        context: NewPostEditorContext = .init(
            analytics: .editorCreatedPage(source: "create_button")
        )
    ) {
        guard rootViewController.presentedViewController == nil else {
            rootViewController.dismiss(animated: true) { [weak self] in
                self?.showNewPageEditor(blog: blog, context: context)
            }
            return
        }
        guard let blog = blog ?? currentOrLastBlog() else { return }
        guard context.content == nil else {
            MainActor.assumeIsolated {
                PostEditorRouter.showNewPage(for: blog, from: rootViewController, context: context)
            }
            return
        }

        var context = context
        MainActor.assumeIsolated {
            context.trackAnalytics(for: blog)
        }
        context.analytics = .none
        PageCoordinator.showLayoutPickerIfNeeded(from: rootViewController, forBlog: blog) {
            [weak self] selectedLayout in
            guard let self else { return }
            var context = context
            context.title = selectedLayout?.title
            context.content = selectedLayout?.content
            MainActor.assumeIsolated {
                PostEditorRouter.showNewPage(for: blog, from: self.rootViewController, context: context)
            }
        }
    }
}
