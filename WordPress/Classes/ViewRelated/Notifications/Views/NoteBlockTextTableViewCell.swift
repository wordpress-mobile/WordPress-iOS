import Foundation
import WordPressShared


class NoteBlockTextTableViewCell: NoteBlockTableViewCell, RichTextViewDataSource, RichTextViewDelegate
{
    // MARK: - Public Properties
    var onUrlClick: (NSURL -> Void)?
    var onAttachmentClick: (NSTextAttachment -> Void)?
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
                textView.linkTextAttributes = [NSForegroundColorAttributeName : unwrappedLinkColor]
            }
        }
    }

    var dataDetectors: UIDataDetectorTypes {
        set {
            textView.dataDetectorTypes = newValue ?? .None
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
            textView.userInteractionEnabled = newValue
        }
        get {
            return textView.userInteractionEnabled
        }
    }

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor
        selectionStyle = .None

        assert(textView != nil)
        textView.contentInset = UIEdgeInsetsZero
        textView.textContainerInset = UIEdgeInsetsZero
        textView.backgroundColor = UIColor.clearColor()
        textView.editable = false
        textView.selectable = true
        textView.dataDetectorTypes = .None
        textView.dataSource = self
        textView.delegate = self

        textView.translatesAutoresizingMaskIntoConstraints = false
    }


    // MARK: - RichTextView Data Source
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        onUrlClick?(URL)
        return false
    }

    func textView(textView: UITextView, didPressLink link: NSURL) {
        onUrlClick?(link)
    }

    func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        onAttachmentClick?(textAttachment)
        return false
    }


    // MARK: - Constants
    static let defaultLabelPadding = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)

    // MARK: - IBOutlets
    @IBOutlet private weak var textView: RichTextView!
}
