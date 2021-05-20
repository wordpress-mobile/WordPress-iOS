/// Encapsulates a command to navigate to a post's comments
final class ReaderCommentAction {
    func execute(post: ReaderPost, origin: UIViewController, promptToAddComment: Bool = false, navigateToCommentID: Int? = nil) {
        guard let postInMainContext = ReaderActionHelpers.postInMainContext(post),
            let controller = ReaderCommentsViewController(post: postInMainContext) else {
            return
        }

        controller.navigateToCommentID = navigateToCommentID as NSNumber?
        controller.promptToAddComment = promptToAddComment
        origin.navigationController?.pushViewController(controller, animated: true)
    }
}
