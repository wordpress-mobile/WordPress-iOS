import Foundation

struct CommentNotification {

    // MARK: - Properties

    let note: Notification
    let postID: UInt
    let siteID: UInt

    var liked: Bool {
        get {
            getCommentLikedStatus()
        } set {
            updateCommentLikedStatus(newValue)
        }
    }

    // MARK: - Init

    init?(note: Notification) {
        guard let postID = note.metaPostID?.uintValue, let siteID = note.metaSiteID?.uintValue else {
            return nil
        }
        self.note = note
        self.postID = postID
        self.siteID = siteID
    }

    // MARK: - Helpers

    func getCommentLikedStatus() -> Bool {
        guard let body = note.body(ofType: .comment),
              let actions = body[Notification.BodyKeys.actions] as? [String: Bool],
              let liked = actions[Notification.ActionsKeys.likeComment]
        else {
            return false
        }
        return liked
    }

    func updateCommentLikedStatus(_ newValue: Bool) {
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
