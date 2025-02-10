import Foundation

final class CommentCellViewModel: NSObject {
    @objc let comment: Comment

    init(comment: Comment) {
        self.comment = comment
    }
}
