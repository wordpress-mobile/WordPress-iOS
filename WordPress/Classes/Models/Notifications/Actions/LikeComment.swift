/// Encapsulates logic to Like a comment
class LikeComment: DefaultNotificationActionCommand {
    enum TitleStrings {
        static let like = AppLocalizedString("Like", comment: "Likes a Comment")
        static let unlike = AppLocalizedString("Liked", comment: "A comment is marked as liked")
    }

    enum TitleHints {
        static let like = AppLocalizedString("Likes the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to like a comment")
        static let unlike = AppLocalizedString("Unlike the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to stop liking a comment")
    }

    override var actionTitle: String {
        return on ? TitleStrings.like : TitleStrings.unlike
    }

    override func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
        guard let block = context.block as? FormattableCommentContent else {
            super.execute(context: context)
            return
        }
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
