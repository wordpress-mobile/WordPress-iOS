import Foundation

@objc public class CommentTableViewCell : NoteBlockCommentTableViewCell
{

    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()

        dataDetectors = .All
    }

    public var commentText: String? {
        didSet {
            if commentText == nil {
                return
            }

            super.attributedCommentText = NSMutableAttributedString(string: commentText!, attributes: WPStyleGuide.Notifications.blockRegularStyle)
        }
    }
}
