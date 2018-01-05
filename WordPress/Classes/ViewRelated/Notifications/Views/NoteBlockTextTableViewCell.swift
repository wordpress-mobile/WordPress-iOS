import Foundation
import WordPressShared


// MARK: - NoteBlockTextTableViewCell
//
class NoteBlockTextTableViewCell: NoteBlockTableViewCell, RichTextViewDataSource, RichTextViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet private weak var textView: RichTextView!

    // MARK: - Public Properties
    @objc var onUrlClick: ((URL) -> Void)?
    @objc var onAttachmentClick: ((NSTextAttachment) -> Void)?
    @objc var attributedText: NSAttributedString? {
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

    @objc var linkColor: UIColor? {
        didSet {
            if let unwrappedLinkColor = linkColor {
                textView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: unwrappedLinkColor]
            }
        }
    }

    @objc var dataDetectors: UIDataDetectorTypes {
        set {
            textView.dataDetectorTypes = newValue
        }
        get {
            return textView.dataDetectorTypes
        }
    }

    @objc var isTextViewSelectable: Bool {
        set {
            textView.selectable = newValue
        }
        get {
            return textView.selectable
        }
    }

    @objc var isTextViewClickable: Bool {
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
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        textView.editable = false
        textView.selectable = true
        textView.dataDetectorTypes = UIDataDetectorTypes()
        textView.dataSource = self
        textView.delegate = self

        textView.translatesAutoresizingMaskIntoConstraints = false
    }


    // MARK: - RichTextView Data Source
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
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
}
