import WordPressKit

struct NotificationActionParser: FormattableContentActionParser {
    private enum Action: String {
        case approve = "approve-comment"
        case follow = "follow"
        case likeComment = "like-comment"
        case likePost = "like-post"
        case reply = "replyto-comment"
        case editComment = "edit-comment"
        case spam = "spam-comment"
        case trash = "trash-comment"
        case none = "none"

        static func matching(value: String) -> Action {
            return Action(rawValue: value) ?? .none
        }
    }

    func parse(_ dictionary: [String: AnyObject]?) -> [FormattableContentAction] {
        guard let allKeys = dictionary?.keys else {
            return []
        }

        return allKeys.compactMap({
            return action(key: $0, on: dictionary?[$0] as? Bool ?? false)
        })
    }

    private func action(key: String, on: Bool) -> FormattableContentAction {
        switch Action.matching(value: key) {
        case .approve:
            return approveAction(on: on)
        case .follow:
            return followAction(on: on)
        case .likeComment:
            return likeCommentAction(on: on)
        case .likePost:
            return likePostAction(on: on)
        case .reply:
            return replyAction(on: on)
        case .spam:
            return spamAction(on: on)
        case .editComment:
            return editCommentAction(on: on)
        case .trash:
            return trashAction(on: on)
        case .none:
            return notFoundAction(on: on)
        }
    }

    private func approveAction(on: Bool) -> FormattableContentAction {
        //return ApproveComment(on: on)
        return ApproveCommentAction(on: on)
    }

    private func followAction(on: Bool) -> FormattableContentAction {
        return FollowAction(on: on)
        //return Follow(on: on)
    }

    private func likeCommentAction(on: Bool) -> FormattableContentAction {
        return LikeCommentAction(on: on)
        //return LikeComment(on: on)
    }

    private func likePostAction(on: Bool) -> FormattableContentAction {
        return LikePostAction(on: on)
        //return LikePost(on: on)
    }

    private func replyAction(on: Bool) -> FormattableContentAction {
        return ReplyToCommentAction(on: on)
        //return ReplyToComment(on: on)
    }

    private func spamAction(on: Bool) -> FormattableContentAction {
        return MarkAsSpamAction(on: on)
        //return MarkAsSpam(on: on)
    }

    private func editCommentAction(on: Bool) -> FormattableContentAction {
        return EditCommentAction(on: on)
        //return EditComment(on: on)
    }

    private func trashAction(on: Bool) -> FormattableContentAction {
        return TrashCommentAction(on: on)
        //return TrashComment(on: on)
    }

    private func notFoundAction(on: Bool) -> FormattableContentAction {
        //return DefaultNotificationAction(on: on)
        return DefaultFormattableContentAction(on: on)
    }
}
