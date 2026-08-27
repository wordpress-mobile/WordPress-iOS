import UIKit
import WebKit
import WordPressComments
import WordPressReader

/// Adapts `WordPressReader.WebCommentContentRenderer` to the module's
/// `CommentContentRendering` seam.
/// TODO: extract `WebCommentContentRenderer` into a package module so
/// `WordPressComments` can depend on it directly instead of this adapter.
final class CommentsWebContentRendererAdapter: NSObject, CommentContentRendering {
    private let renderer: WebCommentContentRenderer = {
        let renderer = WebCommentContentRenderer(isScrollEnabled: true)
        // Breathing room above and below the body; content still scrolls
        // under the region's edges. Horizontal padding is the module's job.
        (renderer.view as? WKWebView)?.scrollView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 16, right: 0)
        return renderer
    }()

    var onLinkTapped: ((URL) -> Void)?
    var view: UIView { renderer.view }

    override init() {
        super.init()
        renderer.delegate = self
    }

    func render(html: String) {
        renderer.render(comment: html)
    }
}

extension CommentsWebContentRendererAdapter: CommentContentRendererDelegate {
    func renderer(_ renderer: CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat, comment: String) {
        // Height is irrelevant: the detail layout gives the web view a fixed
        // region and lets it scroll internally.
    }

    func renderer(_ renderer: CommentContentRenderer, interactedWithURL url: URL) {
        onLinkTapped?(url)
    }
}
