import SwiftUI
import UIKit
import WordPressData
import WordPressShared

struct NewPostEditorContext {
    enum Analytics {
        case editorCreatedPost(source: String, postType: String)
        case editorCreatedPage(source: String)
        case none
    }

    var title: String?
    var content: String?
    var tags: String?
    var prompt: BloggingPrompt?
    var voiceContent: String?
    var initialMedia: [Media]
    var entryPoint: PostEditorEntryPoint
    var analytics: Analytics
    var animated: Bool
    var afterDismiss: (() -> Void)?

    init(
        title: String? = nil,
        content: String? = nil,
        tags: String? = nil,
        prompt: BloggingPrompt? = nil,
        voiceContent: String? = nil,
        initialMedia: [Media] = [],
        entryPoint: PostEditorEntryPoint = .unknown,
        analytics: Analytics = .none,
        animated: Bool = true,
        afterDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.content = content
        self.tags = tags
        self.prompt = prompt
        self.voiceContent = voiceContent
        self.initialMedia = initialMedia
        self.entryPoint = entryPoint
        self.analytics = analytics
        self.animated = animated
        self.afterDismiss = afterDismiss
    }

    func makeEditorContent() throws -> EditorContent {
        let body = voiceContent ?? prompt?.editorContent ?? content ?? ""
        let mediaBlocks = try initialMedia.map(Self.blockHTML(for:))
        let combined = ([body] + mediaBlocks)
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        return EditorContent(title: title ?? "", content: combined)
    }

    func makePostSettings(for blog: Blog) -> PostSettings {
        var settings = PostSettings.defaults(from: blog)
        let names = AbstractPost.makeTags(from: tags ?? "") + (prompt?.editorTags ?? [])
        settings.tags = names.map { PostSettings.Term(id: 0, name: $0) }
        settings.bloggingPromptID = prompt.map { String($0.promptID) }
        return settings
    }

    func trackAnalytics(for blog: Blog) {
        analytics.track(blog: blog)
    }

    func applyLegacyValues(to post: Post) {
        post.postTitle = title
        post.content = content
        post.tags = tags
        post.prepareForPrompt(prompt)
        post.voiceContent = voiceContent
    }

    private static func blockHTML(for media: Media) throws -> String {
        guard
            let id = media.mediaID?.intValue,
            id > 0,
            let remoteURL = media.remoteURL,
            let validatedURL = URL(string: remoteURL),
            let scheme = validatedURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            validatedURL.host?.isEmpty == false
        else {
            throw InitialContextError.invalidMedia
        }

        let absoluteURL = validatedURL.absoluteString
        let url = absoluteURL.escapeHtmlNamedEntities()
        switch media.mediaType {
        case .image:
            let alt = (media.alt ?? "").escapeHtmlNamedEntities()
            return """
                <!-- wp:image {"id":\(id)} -->
                <figure class="wp-block-image"><img src="\(url)" alt="\(alt)" class="wp-image-\(id)"/></figure>
                <!-- /wp:image -->
                """
        case .video:
            return """
                <!-- wp:video {"id":\(id)} -->
                <figure class="wp-block-video"><video controls src="\(url)"></video></figure>
                <!-- /wp:video -->
                """
        case .audio:
            return """
                <!-- wp:audio {"id":\(id)} -->
                <figure class="wp-block-audio"><audio controls src="\(url)"></audio></figure>
                <!-- /wp:audio -->
                """
        case .document, .powerpoint:
            let name = (media.filename ?? absoluteURL).escapeHtmlNamedEntities()
            return """
                <!-- wp:file {"id":\(id),"href":"\(absoluteURL)"} -->
                <div class="wp-block-file"><a href="\(url)">\(name)</a></div>
                <!-- /wp:file -->
                """
        }
    }

    private enum InitialContextError: LocalizedError {
        case invalidMedia

        var errorDescription: String? {
            NSLocalizedString(
                "postEditorRouter.invalidMedia",
                value: "The selected media could not be added.",
                comment: "Error shown when creating a post from media without a usable remote URL."
            )
        }
    }
}

@MainActor
enum PostEditorRouter {
    enum Destination: Equatable {
        case legacy
        case coreREST
    }

    static func destination(for blog: Blog) -> Destination {
        blog.usesCustomPostTypeViewsForPostsAndPages ? .coreREST : .legacy
    }

    static func showNewPost(
        for blog: Blog,
        from presenter: UIViewController,
        context: NewPostEditorContext = .init()
    ) {
        context.trackAnalytics(for: blog)
        switch destination(for: blog) {
        case .coreREST:
            presentCoreRESTEditor(blog: blog, postType: .posts, context: context, from: presenter)
        case .legacy:
            let post = blog.createDraftPost()
            context.applyLegacyValues(to: post)
            let editor = EditPostViewController(post: post)
            editor.insertedMedia = context.initialMedia
            editor.entryPoint = context.entryPoint
            editor.showImmediately = !context.animated
            editor.afterDismiss = context.afterDismiss
            presenter.present(editor, animated: false)
        }
    }

    static func showNewPage(
        for blog: Blog,
        from presenter: UIViewController,
        context: NewPostEditorContext = .init()
    ) {
        context.trackAnalytics(for: blog)
        switch destination(for: blog) {
        case .coreREST:
            presentCoreRESTEditor(blog: blog, postType: .pages, context: context, from: presenter)
        case .legacy:
            let editor = EditPageViewController(
                blog: blog,
                postTitle: context.title,
                content: context.content
            )
            editor.entryPoint = context.entryPoint
            editor.onClose = context.afterDismiss
            presenter.present(editor, animated: false)
        }
    }

    private static func presentCoreRESTEditor(
        blog: Blog,
        postType: PinnedPostType,
        context: NewPostEditorContext,
        from presenter: UIViewController
    ) {
        let controller = CoreRESTPostEditorHostingController(onDismiss: context.afterDismiss)
        let route: CoreRESTPostEditorRoute
        do {
            route = try makeCoreRESTRoute(
                blog: blog,
                postType: postType,
                context: context,
                presentingViewController: controller
            )
        } catch {
            Notice(error: error).post()
            return
        }

        controller.rootView = AnyView(route)
        controller.modalPresentationStyle = .fullScreen
        presenter.present(controller, animated: context.animated)
    }

    static func makeCoreRESTRoute(
        blog: Blog,
        postType: PinnedPostType,
        context: NewPostEditorContext,
        presentingViewController: UIViewController
    ) throws -> CoreRESTPostEditorRoute {
        CoreRESTPostEditorRoute(
            blog: blog,
            postType: postType,
            initialSettings: context.makePostSettings(for: blog),
            initialContent: try context.makeEditorContent(),
            entryPoint: context.entryPoint,
            presentingViewController: presentingViewController
        )
    }
}

@MainActor
final class CoreRESTPostEditorHostingController: UIHostingController<AnyView> {
    private var onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)?) {
        self.onDismiss = onDismiss
        super.init(rootView: AnyView(EmptyView()))
    }

    @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isBeingDismissed || presentingViewController == nil else { return }
        let onDismiss = onDismiss
        self.onDismiss = nil
        onDismiss?()
    }
}

private extension NewPostEditorContext.Analytics {
    func track(blog: Blog) {
        switch self {
        case let .editorCreatedPost(source, postType):
            WPAppAnalytics.track(
                .editorCreatedPost,
                properties: [
                    WPAppAnalyticsKeyTapSource: source,
                    WPAppAnalyticsKeyPostType: postType
                ],
                blog: blog
            )
        case let .editorCreatedPage(source):
            WPAnalytics.track(
                .editorCreatedPage,
                properties: [WPAppAnalyticsKeyTapSource: source],
                blog: blog
            )
        case .none:
            break
        }
    }
}
