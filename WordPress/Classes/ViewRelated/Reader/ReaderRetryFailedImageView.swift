import UIKit
import Gridicons

/// Responding to retry actions.
protocol ReaderRetryFailedImageDelegate: AnyObject {
    func didTapRetry()
}

/// A view that represents a failed image download and includes a retry action.
class ReaderRetryFailedImageView: UIControl {

    // MARK: - Properties

    @IBOutlet weak private var imageView: UIImageView! {
        didSet {
            let iconImage = Gridicon.iconOfType(.imageRemove)
            imageView.image = iconImage.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = UIColor.textSubtle
            imageView.contentMode = .scaleAspectFit
        }
    }

    @IBOutlet weak private var textView: UITextView! {
        didSet {
            textView.textDragInteraction?.isEnabled = false
            textView.adjustsFontForContentSizeCategory = true
        }
    }

    weak var delegate: ReaderRetryFailedImageDelegate?

    // MARK: - Initialization

    /// Override this method to use an alternative xib.
    class func loadFromNib() -> Self {
        guard let retryView = Bundle.main.loadNibNamed("ReaderRetryFailedImageView", owner: nil, options: nil)?.first as? Self else {
            fatalError("ReaderRetryFailedImageView xib must exist. This is an error.")
        }
        return retryView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .imageViewRetryBackground
        textView.attributedText = Self.contentForDisplay()

        addTarget(self, action: #selector(tapAction), for: .touchUpInside)
    }

    // MARK: - Helper Functions

    /// Override this method to customize text view content.
    class func contentForDisplay() -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString()

        let textLocalizedString = NSLocalizedString("Image not loaded.", comment: "Message displayed in image area when a site image fails to load.")
        mutableAttributedString.append(NSAttributedString(string: textLocalizedString, attributes: WPStyleGuide.readerDetailAttributesForRetryText()))

        let singleSpaceString = " "
        mutableAttributedString.append(NSAttributedString(string: singleSpaceString))

        let buttonLocalizedString = NSLocalizedString("Retry", comment: "Retry button title in image area when a site image fails to load.")
        mutableAttributedString.append(NSAttributedString(string: buttonLocalizedString, attributes: WPStyleGuide.readerDetailAttributesForRetryButton()))

        return mutableAttributedString
    }

    // MARK: - Action Handlers

    @objc private func tapAction() {
        delegate?.didTapRetry()
    }
}
