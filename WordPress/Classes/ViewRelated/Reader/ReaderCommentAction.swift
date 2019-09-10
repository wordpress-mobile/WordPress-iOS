/// Encapsulates a command to navigate to a post's comments
final class ReaderCommentAction {
    func execute(post: ReaderPost, origin: UIViewController) {
        guard let postInMainContext = ReaderActionHelpers.postInMainContext(post) else {
            return
        }
        var controller: UIViewController
        if Feature.enabled(.enhancedCommenting) {
            controller = EnhancedCommentingReaderCommentsViewController(post: postInMainContext)
        } else {
            controller = ReaderCommentsViewController(post: postInMainContext)
        }
        origin.navigationController?.pushViewController(controller, animated: true)
    }
}
