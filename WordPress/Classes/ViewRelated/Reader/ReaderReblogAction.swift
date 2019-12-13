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

    /// Executes the reblog action on the origin UIViewController
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
    func presentReblog(blogs: [Blog],
                       readerPost: ReaderPost,
                       origin: UIViewController) {

        switch blogs.count {
        case 0:
            break
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

    private func update(with readerPost: ReaderPost) {
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
