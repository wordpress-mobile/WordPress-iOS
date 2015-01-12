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
        set {
            let text = newValue ?? String()
            attributedCommentText = NSMutableAttributedString(string: text, attributes: Style.blockRegularStyle)
        }
        get {
            return attributedCommentText?.string
        }
    }
    
    typealias Style = WPStyleGuide.Notifications
}
