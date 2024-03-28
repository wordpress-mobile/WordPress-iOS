import Foundation

struct CommentNotification: LikeableNotification {

    // MARK: - Properties

    private let note: Notification
    private let commentID: UInt
    private let siteID: UInt

    // MARK: - Init

    init?(note: Notification) {
        guard let siteID = note.metaSiteID?.uintValue,
              let commentID = note.metaCommentID?.uintValue
        else {
            return nil
        }
        self.note = note
        self.siteID = siteID
        self.commentID = commentID
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
        guard let body = note.body(ofType: .comment),
              let actions = body[Notification.BodyKeys.actions] as? [String: Bool],
              let liked = actions[Notification.ActionsKeys.likeComment]
        else {
            return false
        }
        return liked
    }

    private func updateCommentLikedStatus(_ newValue: Bool) {
        guard var body = note.body(ofType: .comment),
              var actions = body[Notification.BodyKeys.actions] as? [String: Bool]
        else {
            return
        }
        actions[Notification.ActionsKeys.likeComment] = newValue
        body[Notification.BodyKeys.actions] = actions
        self.note.updateBody(ofType: .comment, newValue: body)
    }
}
