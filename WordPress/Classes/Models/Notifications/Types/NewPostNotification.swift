import Foundation

struct NewPostNotification: LikeableNotification {

    // MARK: - Properties

    private let postID: UInt
    private let siteID: UInt
    private let postBody: [String: Any]?
    private let updateBody: (([String: Any]) -> Void)

    // MARK: - Init

    init(
        postID: UInt,
        siteID: UInt,
        postBody: [String: Any]?,
        updateBody: @escaping (([String: Any]) -> Void)
    ) {
        self.postID = postID
        self.siteID = siteID
        self.postBody = postBody
        self.updateBody = updateBody
    }

    // MARK: LikeableNotification

    var liked: Bool {
        get {
            getPostLikedStatus()
        } set {
            updatePostLikedStatus(newValue)
        }
    }

    func toggleLike(using notificationMediator: NotificationSyncMediatorProtocol,
                    isLike: Bool,
                    completion: @escaping (Result<Bool, Error>) -> Void) {
        notificationMediator.toggleLikeForPostNotification(isLike: isLike,
                                                           postID: postID,
                                                           siteID: siteID,
                                                           completion: completion)
    }

    // MARK: - Helpers

    private func getPostLikedStatus() -> Bool {
        guard let actions = postBody?[Notification.BodyKeys.actions] as? [String: Bool],
              let liked = actions[Notification.ActionsKeys.likePost]
        else {
            return false
        }
        return liked
    }

    private func updatePostLikedStatus(_ newValue: Bool) {
        guard var tempBody = postBody,
              var actions = tempBody[Notification.BodyKeys.actions] as? [String: Bool] else {
            return
        }
        actions[Notification.ActionsKeys.likePost] = newValue
        tempBody[Notification.BodyKeys.actions] = actions
        updateBody(tempBody)
    }
}
