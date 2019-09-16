/// Encapsulates a command to navigate to a post's comments
final class ReaderCommentAction {
    func execute(post: ReaderPost, origin: UIViewController) {
        guard let postInMainContext = ReaderActionHelpers.postInMainContext(post) else {
            return
        }
        guard let controller = EnhancedCommentingReaderCommentsViewController(post: postInMainContext) else { return }
        origin.navigationController?.pushViewController(controller, animated: true)
    }
}
