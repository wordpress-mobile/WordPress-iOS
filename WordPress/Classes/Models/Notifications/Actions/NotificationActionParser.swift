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
        let action = ApproveCommentAction(on: on)
        action.command = ApproveComment(on: on)

        return action
    }

    private func followAction(on: Bool) -> FormattableContentAction {
        let action = FollowAction(on: on)
        action.command = Follow(on: on)

        return action
    }

    private func likeCommentAction(on: Bool) -> FormattableContentAction {
        let action = LikeCommentAction(on: on)
        action.command = LikeComment(on: on)

        return action
    }

    private func likePostAction(on: Bool) -> FormattableContentAction {
        let action = LikePostAction(on: on)
        action.command = LikePost(on: on)

        return action
    }

    private func replyAction(on: Bool) -> FormattableContentAction {
        let action = ReplyToCommentAction(on: on)
        action.command = ReplyToComment(on: on)

        return action
    }

    private func spamAction(on: Bool) -> FormattableContentAction {
        let action = MarkAsSpamAction(on: on)
        action.command = MarkAsSpam(on: on)

        return action
    }

    private func editCommentAction(on: Bool) -> FormattableContentAction {
        let action = EditCommentAction(on: on)
        action.command = EditComment(on: on)

        return action
    }

    private func trashAction(on: Bool) -> FormattableContentAction {
        let action = TrashCommentAction(on: on)
        action.command = TrashComment(on: on)

        return action
    }

    private func notFoundAction(on: Bool) -> FormattableContentAction {
        return DefaultFormattableContentAction(on: on)
    }
}
