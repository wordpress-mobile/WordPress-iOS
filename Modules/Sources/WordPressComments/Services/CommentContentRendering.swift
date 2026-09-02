import UIKit

/// Contract: the returned view MUST scroll internally when content exceeds
/// its bounds. The fixed-region detail layout has no other scroll surface
/// and no Show More fallback. The view is given the full region, edge to
/// edge, so its scroll indicator sits at the screen edge; the renderer MUST
/// inset its own content (horizontally by the header's padding, so the text
/// lines up with it).
@MainActor
public protocol CommentContentRendering: AnyObject {
    var view: UIView { get }
    var onLinkTapped: ((URL) -> Void)? { get set }
    func render(html: String)
}
