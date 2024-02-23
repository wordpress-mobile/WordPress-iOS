import Foundation

struct CommentNotification: LikeableNotification {

    // MARK: - Properties

    private let commentID: UInt
    private let siteID: UInt
    private let postBody: [String: Any]?
    private let updateBody: (([String: Any]) -> Void)

    // MARK: - Init

    init(
        commentID: UInt,
        siteID: UInt,
        postBody: [String: Any]?,
        updateBody: @escaping (([String: Any]) -> Void)
    ) {
        self.commentID = commentID
        self.siteID = siteID
        self.postBody = postBody
        self.updateBody = updateBody
    }

    // MARK: LikeableNotification

    var liked: Bool {
        get {
            getCommentLikedStatus()
        } set {
            updateCommentLikedStatus(newValue)
        }
    }

    func toggleLike(using notificationMediator: NotificationSyncMediatorProtocol,
                    isLike: Bool,
                    completion: @escaping (Result<Bool, Error>) -> Void) {
        notificationMediator.toggleLikeForCommentNotification(isLike: isLike,
                                                              commentID: commentID,
                                                              siteID: siteID,
                                                              completion: completion)
    }

    // MARK: - Helpers

    private func getCommentLikedStatus() -> Bool {
        guard let actions = postBody?[Notification.BodyKeys.actions] as? [String: Bool],
              let liked = actions[Notification.ActionsKeys.likeComment]
        else {
            return false
        }
        return liked
    }

    private func updateCommentLikedStatus(_ newValue: Bool) {
        guard var tempBody = postBody,
              var actions = tempBody[Notification.BodyKeys.actions] as? [String: Bool]
        else {
            return
        }
        actions[Notification.ActionsKeys.likeComment] = newValue
        tempBody[Notification.BodyKeys.actions] = actions
        updateBody(tempBody)
    }
}
