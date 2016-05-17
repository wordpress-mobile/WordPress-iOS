import Foundation

/// Any view that represents a post, and allows interaction with it, can implement this protocol.
///
@objc protocol ConfigurablePostViewTEMP {

    /// When called, the view should start representing the specified post object, and send any
    /// interaction events to the delegate.
    ///
    /// - Parameters:
    ///     - post: the post to visually represent.
    ///     - delegate: the delegate that will receive any interaction events.
    ///
    func configure(withPost post: Post, withDelegate delegate: PostCardTableViewCellDelegate)

    /// Same as `configure(delegate:post:)` but only for the purpose of layout.
    ///
    /// - Parameters:
    ///     - post: the post to visually represent.
    ///     - delegate: the delegate that will receive any interaction events.
    ///     - layoutOnly: `true` if the configure call is meant for layout purposes only.
    ///             if set to `false`, this should behave exactly like `configure(delegate:post:)`.
    ///
    func configure(withPost post: Post, withDelegate delegate: PostCardTableViewCellDelegate, forLayoutOnly layoutOnly: Bool)
}
