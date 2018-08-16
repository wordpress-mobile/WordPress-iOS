import WordPressKit

/// Parses the Notification payload. Behaves as a factory that creates different instances of FormattableContentAction for different types of notifications
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
        let command = ApproveComment(on: on)

        return ApproveCommentAction(on: on, command: command)
    }

    private func followAction(on: Bool) -> FormattableContentAction {
        let command = Follow(on: on)

        return FollowAction(on: on, command: command)
    }

    private func likeCommentAction(on: Bool) -> FormattableContentAction {
        let command = LikeComment(on: on)

        return LikeCommentAction(on: on, command: command)
    }

    private func likePostAction(on: Bool) -> FormattableContentAction {
        let command = LikePost(on: on)

        return LikePostAction(on: on, command: command)
    }

    private func replyAction(on: Bool) -> FormattableContentAction {
        let command = ReplyToComment(on: on)

        return ReplyToCommentAction(on: on, command: command)
    }

    private func spamAction(on: Bool) -> FormattableContentAction {
        let command = MarkAsSpam(on: on)

        return MarkAsSpamAction(on: on, command: command)
    }

    private func editCommentAction(on: Bool) -> FormattableContentAction {
        let command = EditComment(on: on)

        return EditCommentAction(on: on, command: command)
    }

    private func trashAction(on: Bool) -> FormattableContentAction {
        let command = TrashComment(on: on)

        return TrashCommentAction(on: on, command: command)
    }

    private func notFoundAction(on: Bool) -> FormattableContentAction {
        let command = DefaultNotificationActionCommand(on: on)
        return DefaultFormattableContentAction(on: on, command: command)
    }
}
