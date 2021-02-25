import Foundation
import WordPressShared


// MARK: - NoteBlockTextTableViewCell
//
class NoteBlockTextTableViewCell: NoteBlockTableViewCell, RichTextViewDataSource, RichTextViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet private weak var textView: RichTextView!
    @IBOutlet private var horizontalEdgeConstraints: [NSLayoutConstraint]!

    /// onUrlClick: Called whenever a URL is pressed within the textView's Area.
    ///
    @objc var onUrlClick: ((URL) -> Void)?

    /// onAttachmentClick: Called whenever a NSTextAttachment receives a press event
    ///
    @objc var onAttachmentClick: ((NSTextAttachment) -> Void)?

    /// Attributed Text!
    ///
    @objc var attributedText: NSAttributedString? {
        set {
            textView.attributedText = newValue
            invalidateIntrinsicContentSize()
        }
        get {
            return textView.attributedText
        }
    }

    /// Indicates if this is a Badge Block
    ///
    override var isBadge: Bool {
        didSet {
            backgroundColor = WPStyleGuide.Notifications.blockBackgroundColorForRichText(isBadge)
        }
    }

    /// Indicates if this should be styled as a larger title
    ///
    var isTitle: Bool = false {
        didSet {
            guard FeatureFlag.milestoneNotifications.enabled else {
                return
            }

            let spacing: CGFloat = isTitle ? Metrics.titleHorizontalSpacing : Metrics.standardHorizontalSpacing
            // Conditional chaining here means this won't crash for any subclasses
            // that don't have edge constraints (such as comment cells)
            horizontalEdgeConstraints?.forEach({ $0.constant = spacing })
        }
    }

    /// TextView's NSLink Color
    ///
    @objc var linkColor: UIColor? {
        didSet {
            if let unwrappedLinkColor = linkColor {
                textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: unwrappedLinkColor]
            }
        }
    }

    /// TextView's Data Detectors
    ///
    @objc var dataDetectors: UIDataDetectorTypes {
        set {
            textView.dataDetectorTypes = newValue
        }
        get {
            return textView.dataDetectorTypes
        }
    }

    /// Wraps Up TextView.selectable Property
    ///
    @objc var isTextViewSelectable: Bool {
        set {
            textView.selectable = newValue
        }
        get {
            return textView.selectable
        }
    }

    /// Wraps Up TextView.isUserInteractionEnabled Property
    ///
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

    override func prepareForReuse() {
        super.prepareForReuse()

        isTitle = false
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

    private enum Metrics {
        static let standardHorizontalSpacing: CGFloat = 20
        static let titleHorizontalSpacing: CGFloat = 40
    }
}
