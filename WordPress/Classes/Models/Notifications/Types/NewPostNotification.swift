import Foundation

struct NewPostNotification {

    // MARK: - Properties

    let note: Notification
    let postID: UInt
    let siteID: UInt

    var liked: Bool {
        get {
            getPostLikedStatus()
        } set {
            updatePostLikedStatus(newValue)
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

    func getPostLikedStatus() -> Bool {
        guard let body = note.body(ofType: .post),
              let actions = body[Notification.BodyKeys.actions] as? [String: Bool],
              let liked = actions[Notification.ActionsKeys.likePost]
        else {
            return false
        }
        return liked
    }

    func updatePostLikedStatus(_ newValue: Bool) {
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
