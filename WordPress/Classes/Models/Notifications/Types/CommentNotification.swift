import Foundation

struct CommentNotification {

    // MARK: - Properties

    let note: Notification
    let postID: UInt
    let siteID: UInt

    // MARK: - Init

    init?(note: Notification) {
        guard let postID = note.metaPostID?.uintValue, let siteID = note.metaSiteID?.uintValue else {
            return nil
        }
        self.note = note
        self.postID = postID
        self.siteID = siteID
    }
}
