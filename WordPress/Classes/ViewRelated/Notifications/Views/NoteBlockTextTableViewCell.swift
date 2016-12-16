import Foundation
import WordPressShared


class NoteBlockTextTableViewCell: NoteBlockTableViewCell, RichTextViewDataSource, RichTextViewDelegate
{
    // MARK: - Public Properties
    var onUrlClick: ((URL) -> Void)?
    var onAttachmentClick: ((NSTextAttachment) -> Void)?
    var attributedText: NSAttributedString? {
        set {
            textView.attributedText = newValue
            invalidateIntrinsicContentSize()
        }
        get {
            return textView.attributedText
        }
    }

    override var isBadge: Bool {
        didSet {
            backgroundColor = WPStyleGuide.Notifications.blockBackgroundColorForRichText(isBadge)
        }
    }

    var linkColor: UIColor? {
        didSet {
            if let unwrappedLinkColor = linkColor {
                textView.linkTextAttributes = [NSForegroundColorAttributeName as NSObject : unwrappedLinkColor]
            }
        }
    }

    var dataDetectors: UIDataDetectorTypes {
        set {
            textView.dataDetectorTypes = newValue
        }
        get {
            return textView.dataDetectorTypes
        }
    }

    var isTextViewSelectable: Bool {
        set {
            textView.selectable = newValue
        }
        get {
            return textView.selectable
        }
    }

    var isTextViewClickable: Bool {
        set {
            textView.isUserInteractionEnabled = newValue
        }
        get {
            return textView.isUserInteractionEnabled
        }
    }

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor
        selectionStyle = .none

        assert(textView != nil)
        textView.contentInset = UIEdgeInsets.zero
        textView.textContainerInset = UIEdgeInsets.zero
        textView.backgroundColor = UIColor.clear
        textView.editable = false
        textView.selectable = true
        textView.dataDetectorTypes = UIDataDetectorTypes()
        textView.dataSource = self
        textView.delegate = self

        textView.translatesAutoresizingMaskIntoConstraints = false

        // TODO:
        // Nuke this snippet once Readability is in place. REF. #6085
        let maxWidth = WPTableViewFixedWidth
        let padding = type(of: self).defaultLabelPadding
        textView.preferredMaxLayoutWidth = maxWidth - padding.left - padding.right
    }


    // MARK: - RichTextView Data Source
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        onUrlClick?(URL)
        return false
    }

    func textView(_ textView: UITextView, didPressLink link: URL) {
        onUrlClick?(link)
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
        onAttachmentClick?(textAttachment)
        return false
    }


    // MARK: - Constants
    static let defaultLabelPadding = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)

    // MARK: - IBOutlets
    @IBOutlet fileprivate weak var textView: RichTextView!
}
