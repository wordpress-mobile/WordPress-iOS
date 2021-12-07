protocol CommentContentRenderer {
    var delegate: CommentContentRendererDelegate? { get set }

    init(comment: Comment)

    func render() -> UIView

    func matchesContent(from comment: Comment) -> Bool
}

protocol CommentContentRendererDelegate: AnyObject {
    /// Called when the rendering process completes. Note that this method is only called when using complex rendering methods that involves
    /// asynchronous operations, so the container can readjust its size at a later time.
    func renderer(_ renderer: CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat)

    /// Called whenever the user interacts with a URL within the rendered content.
    func renderer(_ renderer: CommentContentRenderer, interactedWithURL url: URL)
}
