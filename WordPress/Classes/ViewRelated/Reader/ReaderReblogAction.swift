/// Encapsulates a command to reblog a post
class ReaderReblogAction {

    private let blogService: BlogService
    private let presenter: ReblogPresenter

    init(blogService: BlogService? = nil,
         presenter: ReblogPresenter = ReblogPresenter()) {
        self.presenter = presenter

        // fallback for self.blogService
        func makeBlogService() -> BlogService {
            let context = ContextManager.sharedInstance().mainContext
            return BlogService(managedObjectContext: context)
        }
        self.blogService = blogService ?? makeBlogService()
    }

    /// Executes the reblog action on the origin UIViewController
    func execute(readerPost: ReaderPost, origin: UIViewController) {
        presenter.presentReblog(blogService: blogService,
                                readerPost: readerPost,
                                origin: origin)
    }
}


/// Presents the approptiate reblog scene, depending on the number of available sites
class ReblogPresenter {
    private let postService: PostService

    private struct NoSitesConfiguration {
        static let noSitesTitle = NSLocalizedString("No available sites",
                                                    comment: "A short message that informs the user no sites could be loaded in the share extension.")
        static let noSitesSubtitle = NSLocalizedString("Once you create a site, you can reblog content that you like to your own site.",
                                                       comment: "A subtitle with more detailed info for the user when no sites could be found.")
        static let manageSitesLabel = NSLocalizedString("Manage Sites",
                                                        comment: "Button title. Tapping lets the user manage the sites they follow.")
        static let backButtonTitle = NSLocalizedString("Back",
                                                       comment: "Back button title.")
    }

    init(postService: PostService? = nil) {

        // fallback for self.postService
        func makePostService() -> PostService {
            let context = ContextManager.sharedInstance().mainContext
            return PostService(managedObjectContext: context)
        }
        self.postService = postService ?? makePostService()
    }

    /// Presents the reblog screen(s)
    func presentReblog(blogService: BlogService,
                       readerPost: ReaderPost,
                       origin: UIViewController) {

        let blogCount = blogService.blogCountForAllAccounts()

        switch blogCount {
        case 0:
            presentNoSitesScreen(origin: origin)
        case 1:
            guard let blog = blogService.blogsForAllAccounts().first else {
                return
            }
            presentEditor(with: readerPost, blog: blog, origin: origin)
        default:
            guard let blog = blogService.lastUsedOrFirstBlog() else {
                return
            }
            presentEditor(with: readerPost, blog: blog, origin: origin, presentBlogSelector: true)
        }
    }
    
    /// presents the editor when users have at least one blog site
    private func presentEditor(with readerPost: ReaderPost,
                               blog: Blog,
                               origin: UIViewController,
                               presentBlogSelector: Bool = false) {

        let post = postService.createDraftPost(for: blog)
        post.prepareForReblog(with: readerPost)

        let editor = EditPostViewController(post: post, loadAutosaveRevision: false)
        editor.modalPresentationStyle = .fullScreen
        editor.openWithBlogSelector = presentBlogSelector

        origin.present(editor, animated: false)
    }
    
    /// presents the no sites screen, with related actions
    private func presentNoSitesScreen(origin: UIViewController) {
        let controller = NoResultsViewController.controllerWith(title: NoSitesConfiguration.noSitesTitle,
                                                                buttonTitle: NoSitesConfiguration.manageSitesLabel,
                                                                subtitle: NoSitesConfiguration.noSitesSubtitle)
        // add handlers to NoResultsController
        controller.actionButtonHandler = { [weak origin] in
            guard let tabBarController = origin?.tabBarController as? WPTabBarController else {
                return
            }
            controller.dismiss(animated: true) {
                tabBarController.showMySitesTab()
            }
        }

        controller.dismissButtonHandler = {
            controller.dismiss(animated: true)
        }

        controller.showDismissButton(title: NoSitesConfiguration.backButtonTitle)

        let navigationController = AdaptiveNavigationController(rootViewController: controller)

        if #available(iOS 13.0, *) {
            navigationController.modalPresentationStyle = .automatic
        } else {
            // suits both iPad and iPhone
            navigationController.modalPresentationStyle = .pageSheet
        }
        
        origin.present(navigationController, animated: true)
    }
}

/// takes a newly created Post and injects a ReaderPost content in it
fileprivate extension Post {
    /// Formats the post content for reblogging
    func prepareForReblog(with readerPost: ReaderPost) {
        // update the post
        update(with: readerPost)
        // initialize the content
        var content = String()
        // add the quoted summary to the content, if it exists
        if let summary = readerPost.summary {
            var citation: String?
            // add the optional citation
            if let permaLink = readerPost.permaLink, let title = readerPost.titleForDisplay() {
                citation = ReblogFormatter.hyperLink(url: permaLink, text: title)
            }
            content = ReblogFormatter.wordPressQuote(text: summary, citation: citation)
        }
        // insert the image on top of the content
        if let image = readerPost.featuredImage {
            content = ReblogFormatter.htmlImage(image: image) + content
        }
        self.content = content
    }

    func update(with readerPost: ReaderPost) {
        self.postTitle = readerPost.titleForDisplay()
        self.pathForDisplayImage = readerPost.featuredImage
        self.permaLink = readerPost.permaLink
    }
}


/// Contains methods to format Gutenberg-ready HTML content
struct ReblogFormatter {

    static func wordPressQuote(text: String, citation: String? = nil) -> String {
        var formattedText = embedInParagraph(text: text)
        if let citation = citation {
            formattedText.append(embedinCitation(html: citation))
        }
        return embedInWpQuote(html: formattedText)
    }

    static func hyperLink(url: String, text: String) -> String {
        return "<a href=\"\(url)\">\(text)</a>"
    }

    static func htmlImage(image: String) -> String {
        return embedInWpParagraph(text: "<img src=\"\(image)\">")
    }

    private static func embedInWpParagraph(text: String) -> String {
        return "<!-- wp:paragraph -->\n<p>\(text)</p>\n<!-- /wp:paragraph -->"
    }

    private static func embedInWpQuote(html: String) -> String {
        return "<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\">\(html)</blockquote>\n<!-- /wp:quote -->"
    }

    private static func embedInParagraph(text: String) -> String {
        return "<p>\(text)</p>"
    }

    private static func embedinCitation(html: String) -> String {
        return "<cite>\(html)</cite>"
    }
}
