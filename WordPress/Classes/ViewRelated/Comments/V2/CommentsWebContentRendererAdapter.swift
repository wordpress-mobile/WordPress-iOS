import UIKit
import WordPressComments
import WordPressReader

/// Adapts `WordPressReader.WebCommentContentRenderer` to the module's
/// `CommentContentRendering` seam.
/// TODO: extract `WebCommentContentRenderer` into a package module so
/// `WordPressComments` can depend on it directly instead of this adapter.
final class CommentsWebContentRendererAdapter: NSObject, CommentContentRendering {
    private let renderer: WebCommentContentRenderer = {
        let renderer = WebCommentContentRenderer(isScrollEnabled: true)
        // The web view fills the region so its scroll indicator sits at the
        // screen edge; the document insets the text instead. Scroll view
        // content insets would not work horizontally: the document keeps the
        // frame width and pans sideways.
        renderer.contentPadding = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
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
