import Foundation

struct NewPostNotification {

    let note: Notification

    // MARK: - API

    var liked: Bool {
        get {
            getPostLikedStatus()
        } set {
            updatePostLikedStatus(newValue)
        }
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
