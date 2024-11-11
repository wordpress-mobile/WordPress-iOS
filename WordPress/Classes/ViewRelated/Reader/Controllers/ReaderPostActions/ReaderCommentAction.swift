/// Encapsulates a command to navigate to a post's comments
final class ReaderCommentAction {
    func execute(post: ReaderPost,
                 origin: UIViewController,
                 promptToAddComment: Bool = false,
                 navigateToCommentID: Int? = nil,
                 source: ReaderCommentsSource) {
        guard let controller = ReaderCommentsViewController(post: post, source: source) else {
            return
        }
        controller.navigateToCommentID = navigateToCommentID as NSNumber?
        controller.promptToAddComment = promptToAddComment
        controller.trackCommentsOpened()
        controller.hidesBottomBarWhenPushed = true
        origin.navigationController?.pushViewController(controller, animated: true)
    }
}
