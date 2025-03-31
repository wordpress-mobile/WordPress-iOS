import UIKit
import WordPressShared

extension UIButton {
    /// Applies the style that looks like a plain text link.
    func applyLinkButtonStyle() {
        backgroundColor = .clear
        titleLabel?.font = WPStyleGuide.fontForTextStyle(.body)
        titleLabel?.textAlignment = .natural

        let buttonTitleColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonColor ?? WordPressAuthenticator.shared.style.textButtonColor
        let buttonHighlightColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonHighlightColor ?? WordPressAuthenticator.shared.style.textButtonHighlightColor
        setTitleColor(buttonTitleColor, for: .normal)
        setTitleColor(buttonHighlightColor, for: .highlighted)
    }
}
