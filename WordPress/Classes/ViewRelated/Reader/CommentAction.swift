final class CommentAction {
    func execute(post: ReaderPost, origin: UIViewController) {
        guard let postInMainContext = ActionHelpers.postInMainContext(post),
            let controller = ReaderCommentsViewController(post: postInMainContext) else {
            return
        }

        origin.navigationController?.pushViewController(controller, animated: true)
    }
}
