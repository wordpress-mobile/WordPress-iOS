import UIKit

/// Contract: the returned view MUST scroll internally when content exceeds
/// its bounds. The fixed-region detail layout has no other scroll surface
/// and no Show More fallback.
@MainActor
public protocol CommentContentRendering: AnyObject {
    var view: UIView { get }
    var onLinkTapped: ((URL) -> Void)? { get set }
    func render(html: String)
}
