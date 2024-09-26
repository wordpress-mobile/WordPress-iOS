/// Defines methods related to Comment content rendering.
///
protocol CommentContentRenderer {
    var delegate: CommentContentRendererDelegate? { get set }

    init(comment: Comment)

    /// Returns a view component that's configured to display the formatted content of the comment.
    ///
    /// Note that the renderer *might* return a view with the wrong sizing at first, but it should update its delegate with the correct height
    /// through the `renderer(_:asyncRenderCompletedWithHeight:)` method.
    func render() -> UIView

    /// Checks if the provided comment contains the same content as the current one that's processed by the renderer.
    /// This is used as an optimization strategy by the caller to skip view creations if the rendered content matches the one provided in the parameter.
    func matchesContent(from comment: Comment) -> Bool
}

protocol CommentContentRendererDelegate: AnyObject {
    /// Called when the rendering process completes. Note that this method is only called when using complex rendering methods that involves
    /// asynchronous operations, so the container can readjust its size at a later time.
    func renderer(_ renderer: CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat)

    /// Called whenever the user interacts with a URL within the rendered content.
    func renderer(_ renderer: CommentContentRenderer, interactedWithURL url: URL)
}
