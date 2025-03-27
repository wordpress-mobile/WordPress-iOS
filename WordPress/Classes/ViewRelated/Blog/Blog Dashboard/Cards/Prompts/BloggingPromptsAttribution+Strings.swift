import UIKit
import WordPressUI
import Gridicons

extension BloggingPromptsAttribution {

    var attributedText: NSAttributedString {
        let baseText = String(format: Strings.fromTextFormat, source)
        let attributedText = NSMutableAttributedString(string: baseText, attributes: Constants.baseAttributes)
        guard let range = baseText.range(of: source) else {
            return attributedText
        }

        let nsRange = NSRange(range, in: baseText)
        attributedText.addAttributes(Constants.sourceAttributes, range: nsRange)

        return attributedText
    }

    var source: String {
        switch self {
        case .dayone: return Strings.dayOne
        case .bloganuary: return Strings.bloganuary
        }
    }

    var iconImage: UIImage? {
        switch self {
        case .dayone: return Constants.dayOneIcon
        case .bloganuary: return Constants.bloganuaryIcon
        }
    }

    var externalURL: URL? {
        switch self {
        case .dayone: return Constants.dayOneURL
        case .bloganuary: return nil
        }
    }

    var trailingImage: UIImage? {
        guard let _ = externalURL else {
            return nil
        }

        return Constants.linkIcon
    }

    private struct Strings {
        static let fromTextFormat = NSLocalizedString("From %1$@", comment: "Format for blogging prompts attribution. %1$@ is the attribution source.")
        static let dayOne = "Day One"
        static let bloganuary = "Bloganuary"
    }

    private struct Constants {
        static let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(.caption1),
            .foregroundColor: UIColor.secondaryLabel,
        ]
        static let sourceAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .medium),
            .foregroundColor: UIColor.label,
        ]
        static let dayOneIconSize = CGSize(width: 18, height: 18)
        static let dayOneIcon = UIImage(named: "logo-dayone")?.resized(to: Constants.dayOneIconSize)
        static let dayOneURL = URL(string: "https://dayoneapp.com/?utm_source=jetpack&utm_medium=prompts")

        static let linkIconSize = CGFloat(10)
        static let linkIcon = UIImage(systemName: "link", withConfiguration: UIImage.SymbolConfiguration(pointSize: linkIconSize))

        /// This is computed so it can react accordingly on color scheme changes.
        static var bloganuaryIcon: UIImage? {
            UIImage(named: "logo-bloganuary")?
                .withRenderingMode(.alwaysTemplate)
                .resized(to: Constants.bloganuaryIconSize)
                .withAlignmentRectInsets(UIEdgeInsets(.all, -6.0))
                .withTintColor(.label)
        }

        /// Unlike the dayOne icon, the bloganuary icon has no implicit 6px padding surrounding the icon.
        static let bloganuaryIconSize = CGSize(width: 12, height: 12)
    }
}
