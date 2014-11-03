import Foundation

@objc public class CommentTableViewCell : NoteBlockCommentTableViewCell
{

    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()

        dataDetectors = .All
        isTextViewSelectable = true
    }

    public var commentText: String? {
        didSet {
            if commentText == nil {
                return
            }

            let style = WPStyleGuide.Notifications.blockRegularStyle
            super.attributedCommentText = NSMutableAttributedString(string: commentText!, attributes: style)
        }
    }
}
