/// Encapsulates logic to Like a comment
class LikeComment: DefaultNotificationActionCommand {
    enum TitleStrings {
        static let like = NSLocalizedString("Like", comment: "Likes a Comment")
        static let unlike = NSLocalizedString("Liked", comment: "A comment is marked as liked")
    }

    enum TitleHints {
        static let like = NSLocalizedString("Likes the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to like a comment")
        static let unlike = NSLocalizedString("Unlike the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to stop liking a comment")
    }

    override func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction? {
        let action = UIContextualAction(style: .normal,
                                        title: on ? TitleStrings.like : TitleStrings.unlike, handler: handler)
        action.backgroundColor = .primary
        return action
    }

    override func execute<ContentType: FormattableCommentContent>(context: ActionContext<ContentType>) {
        let block = context.block
        if on {
            removeLike(block: block)
        } else {
            like(block: block)
        }
    }

    private func like(block: FormattableCommentContent) {
        actionsService?.likeCommentWithBlock(block)
    }

    private func removeLike(block: FormattableCommentContent) {
        actionsService?.unlikeCommentWithBlock(block)
    }
}
