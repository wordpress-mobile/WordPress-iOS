import Foundation

struct NewPostNotification: LikeableNotification {

    // MARK: - Properties

    private let note: Notification
    private let postID: UInt
    private let siteID: UInt

    // MARK: - Init

    init?(note: Notification) {
        guard let postID = note.metaPostID?.uintValue, let siteID = note.metaSiteID?.uintValue else {
            return nil
        }
        self.note = note
        self.postID = postID
        self.siteID = siteID
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
        guard let body = note.body(ofType: .post),
              let actions = body[Notification.BodyKeys.actions] as? [String: Bool],
              let liked = actions[Notification.ActionsKeys.likePost]
        else {
            return false
        }
        return liked
    }

    private func updatePostLikedStatus(_ newValue: Bool) {
        guard var body = note.body(ofType: Notification.BodyType.post),
              var actions = body[Notification.BodyKeys.actions] as? [String: Bool]
        else {
            return
        }
        actions[Notification.ActionsKeys.likePost] = newValue
        body[Notification.BodyKeys.actions] = actions
        self.note.updateBody(ofType: .post, newValue: body)
    }
}
