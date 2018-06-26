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
            return action(key: $0)
        })
    }

    private func action(key: String) -> NotificationAction {
        switch Action.matching(value: key) {
        case .approve:
            return approveAction()
        case .follow:
            return followAction()
        case .likeComment:
            return likeCommentAction()
        case .likePost:
            return likePostAction()
        case .reply:
            return replyAction()
        case .spam:
            return spamAction()
        case .editComment:
            return editCommentAction()
        case .trash:
            return trashAction()
        case .none:
            return notFoundAction()
        }
    }

    private func approveAction() -> NotificationAction {
        return ApproveComment()
    }

    private func followAction() -> NotificationAction {
        return Follow()
    }

    private func likeCommentAction() -> NotificationAction {
        return LikeComment()
    }

    private func likePostAction() -> NotificationAction {
        return LikePost()
    }

    private func replyAction() -> NotificationAction {
        return ReplyToComment()
    }

    private func spamAction() -> NotificationAction {
        return MarkAsSpam()
    }

    private func editCommentAction() -> NotificationAction {
        return EditComment()
    }

    private func trashAction() -> NotificationAction {
        return TrashComment()
    }

    private func notFoundAction() -> NotificationAction {
        print("======= printing not found action ")
        return DefaultNotificationAction()
    }
}
