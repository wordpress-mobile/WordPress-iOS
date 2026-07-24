import Foundation
import SwiftUI
import WordPressData
import WordPressShared

extension RootViewPresenter {
    func currentOrLastBlog() -> Blog? {
        if let blog = currentlyVisibleBlog() {
            return blog
        }
        let context = ContextManager.shared.mainContext
        return Blog.lastUsedOrFirst(in: context)
    }

    func showPostEditor(
        animated: Bool = true,
        post: Post? = nil,
        blog: Blog? = nil,
        completion afterDismiss: (() -> Void)? = nil
    ) {
        if rootViewController.presentedViewController != nil {
            rootViewController.dismiss(animated: false)
        }

        guard let blog = blog ?? currentOrLastBlog() else {
            return
        }

        let editor: EditPostViewController
        if let post {
            editor = EditPostViewController(post: post)
        } else {
            editor = EditPostViewController(blog: blog)
        }
        editor.modalPresentationStyle = .fullScreen
        editor.showImmediately = !animated
        editor.afterDismiss = afterDismiss

        let properties = [WPAppAnalyticsKeyTapSource: "create_button", WPAppAnalyticsKeyPostType: "post"]
        WPAppAnalytics.track(.editorCreatedPost, properties: properties, blog: blog)
        rootViewController.present(editor, animated: false)
    }

    func showCoreRESTPostEditor(blog: Blog) {
        if rootViewController.presentedViewController != nil {
            rootViewController.dismiss(animated: false)
        }

        let properties = [WPAppAnalyticsKeyTapSource: "create_button", WPAppAnalyticsKeyPostType: "post"]
        WPAppAnalytics.track(.editorCreatedPost, properties: properties, blog: blog)
        presentCoreRESTEditor(blog: blog, postType: .posts)
    }

    /// - parameter blog: Blog to a add a page to. Uses the current or last blog if not provided
    func showPageEditor(
        blog: Blog? = nil,
        title: String? = nil,
        content: String? = nil,
        source: String = "create_button"
    ) {

        // If we are already showing a view controller, dismiss and show the editor afterward
        guard rootViewController.presentedViewController == nil else {
            rootViewController.dismiss(animated: true) { [weak self] in
                self?.showPageEditor(blog: blog, title: title, content: content, source: source)
            }
            return
        }
        guard let blog = blog ?? self.currentOrLastBlog() else {
            return
        }
        guard content == nil else {
            showEditor(blog: blog, title: title, content: content)
            return
        }

        WPAnalytics.track(
            WPAnalyticsEvent.editorCreatedPage,
            properties: [WPAppAnalyticsKeyTapSource: source],
            blog: blog
        )
        PageCoordinator.showLayoutPickerIfNeeded(from: rootViewController, forBlog: blog) {
            [weak self] selectedLayout in
            self?.showEditor(blog: blog, title: selectedLayout?.title, content: selectedLayout?.content)
        }
    }

    func showCoreRESTPageEditor(blog: Blog, source: String = "create_button") {
        guard rootViewController.presentedViewController == nil else {
            rootViewController.dismiss(animated: true) { [weak self] in
                self?.showCoreRESTPageEditor(blog: blog, source: source)
            }
            return
        }
        WPAnalytics.track(
            WPAnalyticsEvent.editorCreatedPage,
            properties: [WPAppAnalyticsKeyTapSource: source],
            blog: blog
        )
        PageCoordinator.showLayoutPickerIfNeeded(from: rootViewController, forBlog: blog) {
            [weak self] selectedLayout in
            let initialContent = selectedLayout.map {
                EditorContent(title: $0.title ?? "", content: $0.content)
            }
            self?.presentCoreRESTEditor(blog: blog, postType: .pages, initialContent: initialContent)
        }
    }

    private func presentCoreRESTEditor(
        blog: Blog,
        postType: PinnedPostType,
        initialContent: EditorContent? = nil
    ) {
        let controller = UIHostingController(rootView: AnyView(EmptyView()))
        controller.rootView = AnyView(
            CoreRESTPostEditorRoute(
                blog: blog,
                postType: postType,
                initialContent: initialContent,
                presentingViewController: controller
            )
        )
        controller.modalPresentationStyle = .fullScreen
        rootViewController.present(controller, animated: true)
    }

    private func showEditor(blog: Blog, title: String?, content: String?) {
        let editorViewController = EditPageViewController(blog: blog, postTitle: title, content: content)
        rootViewController.present(editorViewController, animated: false)
    }
}
