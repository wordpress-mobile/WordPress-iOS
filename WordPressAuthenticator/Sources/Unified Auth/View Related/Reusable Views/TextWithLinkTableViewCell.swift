import UIKit

/// TextWithLinkTableViewCell: a button with the title regular text and an underlined link.
///
class TextWithLinkTableViewCell: UITableViewCell {

    /// Public properties
    ///
    static let reuseIdentifier = "TextWithLinkTableViewCell"
    var actionHandler: (() -> Void)?

    /// Private properties
    ///
    @IBOutlet private weak var button: UIButton!
    @IBAction private func buttonTapped(_ sender: UIButton) {
        actionHandler?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    /// Creates an attributed string from the provided marked text and assigns it to the button title.
    ///
    /// - Parameters:
    ///   - markedText: string with the text to be formatted as a link marked with "_".
    ///     Example: "this _is_ a link" will format "is" as an underlined link.
    ///   - accessibilityTrait: accessibilityTrait of button (optional)
    ///
    func configureButton(markedText text: String, accessibilityTrait: UIAccessibilityTraits = .link) {
        let textColor = WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor ?? WordPressAuthenticator.shared.style.subheadlineColor
        let linkColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonColor ?? WordPressAuthenticator.shared.style.textButtonColor
        let linkHighlightColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonHighlightColor ?? WordPressAuthenticator.shared.style.textButtonHighlightColor

        let attributedString = text.underlined(color: textColor, underlineColor: linkColor)
        let highlightAttributedString = text.underlined(color: textColor, underlineColor: linkHighlightColor)

        button.setAttributedTitle(attributedString, for: .normal)
        button.setAttributedTitle(highlightAttributedString, for: .highlighted)
        button.accessibilityTraits = accessibilityTrait
    }
}
