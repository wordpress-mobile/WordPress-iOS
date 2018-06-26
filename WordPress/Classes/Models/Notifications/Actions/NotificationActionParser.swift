struct NotificationActionParser {
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

    func parse(_ dictionary: [String: AnyObject]?) -> [NotificationAction] {
        guard let allKeys = dictionary?.keys else {
            return []
        }

        return allKeys.compactMap({
            return action(key: $0, enabled: dictionary?[$0] as? Bool ?? false)
        })
    }

    private func action(key: String, enabled: Bool) -> NotificationAction {
        switch Action.matching(value: key) {
        case .approve:
            return approveAction(enabled: enabled)
        case .follow:
            return followAction(enabled: enabled)
        case .likeComment:
            return likeCommentAction(enabled: enabled)
        case .likePost:
            return likePostAction(enabled: enabled)
        case .reply:
            return replyAction(enabled: enabled)
        case .spam:
            return spamAction(enabled: enabled)
        case .editComment:
            return editCommentAction(enabled: enabled)
        case .trash:
            return trashAction(enabled: enabled)
        case .none:
            return notFoundAction(enabled: enabled)
        }
    }

    private func approveAction(enabled: Bool) -> NotificationAction {
        return ApproveComment(enabled: enabled)
    }

    private func followAction(enabled: Bool) -> NotificationAction {
        return Follow(enabled: enabled)
    }

    private func likeCommentAction(enabled: Bool) -> NotificationAction {
        return LikeComment(enabled: enabled)
    }

    private func likePostAction(enabled: Bool) -> NotificationAction {
        return LikePost(enabled: enabled)
    }

    private func replyAction(enabled: Bool) -> NotificationAction {
        return ReplyToComment(enabled: enabled)
    }

    private func spamAction(enabled: Bool) -> NotificationAction {
        return MarkAsSpam(enabled: enabled)
    }

    private func editCommentAction(enabled: Bool) -> NotificationAction {
        return EditComment(enabled: enabled)
    }

    private func trashAction(enabled: Bool) -> NotificationAction {
        return TrashComment(enabled: enabled)
    }

    private func notFoundAction(enabled: Bool) -> NotificationAction {
        print("======= printing not found action ")
        return DefaultNotificationAction(enabled: enabled)
    }
}
