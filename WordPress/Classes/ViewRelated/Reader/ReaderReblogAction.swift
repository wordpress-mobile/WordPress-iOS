import Foundation

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

    /// Executes the reblog action
    /// - Parameters:
    ///   - readerPost: source ReaderPost instance
    ///   - origin: UIViewController that will present the reblog screen(s)
    func execute(readerPost: ReaderPost, origin: UIViewController) {
        presenter.presentReblog(blogs: blogService.blogsForAllAccounts(),
                                readerPost: readerPost,
                                origin: origin)
    }
}

/// Presents the approptiate reblog scene, depending on the number of available sites
class ReblogPresenter {
    private let postService: PostService

    init(postService: PostService? = nil) {

        // fallback for self.postService
        func makePostService() -> PostService {
            let context = ContextManager.sharedInstance().mainContext
            return PostService(managedObjectContext: context)
        }
        self.postService = postService ?? makePostService()
    }

    /// Presents the reblog screen(s)
    /// - Parameters:
    ///   - blogs: available blog sites
    ///   - readerPost: source ReaderPost instance
    ///   - origin: UIViewController that will present the reblog screen(s)
    func presentReblog(blogs: [Blog],
                       readerPost: ReaderPost,
                       origin: UIViewController) {

        switch blogs.count {
        case 0:
            guard let tabBarController = origin.tabBarController as? WPTabBarController else {
                return
            }
            tabBarController.switchMySitesTabToAddNewSite()
        case 1:
            let post = postService.createDraftPost(for: blogs[0])
            post.prepareForReblog(with: readerPost)
            let editor = EditPostViewController(post: post, loadAutosaveRevision: false)
            editor.modalPresentationStyle = .fullScreen
            origin.present(editor, animated: false)

        default:
            break
        }
    }
}

// Formats the contet for reblogging
fileprivate extension Post {
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
            self.pathForDisplayImage = image
            content = ReblogFormatter.htmlImage(image: image) + content
        }
        self.content = content
    }

    private func update(with readerPost: ReaderPost) {
        self.postTitle = readerPost.titleForDisplay()
        self.pathForDisplayImage = readerPost.featuredImage
        self.permaLink = readerPost.permaLink
    }
}

/// Contains methods to format Gutenberg-ready HTML content
fileprivate struct ReblogFormatter {
    /// Gutenberg-ready quote
    /// - Parameters:
    ///   - text: text to quote
    ///   - citation: optional citation to add to the quote
    static func wordPressQuote(text: String, citation: String? = nil) -> String {
        var formattedText = embedInParagraph(text: text)
        if let citation = citation {
            formattedText.append(embedinCitation(html: citation))
        }
        return embedInWpQuote(html: formattedText)
    }
    /// creates an html hyperlinh
    static func hyperLink(url: String, text: String) -> String {
        return "<a href=\"\(url)\">\(text)</a>"
    }
    /// creates an html image url and embeds it into a Gutenberg-ready paragraph
    static func htmlImage(image: String) -> String {
        return embedInWpParagraph(text: "<img src=\"\(image)\">")
    }

    /// embeds a text in a Gutenberg-ready html paragraph
    private static func embedInWpParagraph(text: String) -> String {
        return "<!-- wp:paragraph -->\n<p>\(text)</p>\n<!-- /wp:paragraph -->"
    }
    /// embeds an html string in a Gutenberg-ready quote
    private static func embedInWpQuote(html: String) -> String {
        return "<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\">\(html)</blockquote>\n<!-- /wp:quote -->"
    }
    /// embeds a text in an html paragraph
    private static func embedInParagraph(text: String) -> String {
        return "<p>\(text)</p>"
    }
    /// embeds a text or an html element in a citation
    private static func embedinCitation(html: String) -> String {
        return "<cite>\(html)</cite>"
    }
}
