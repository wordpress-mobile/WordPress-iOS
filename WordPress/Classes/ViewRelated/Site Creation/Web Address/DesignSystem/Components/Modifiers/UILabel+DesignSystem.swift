import UIKit

// MARK: - UIKit.UIFont: TextStyle
extension TextStyle {
    var uiFont: UIFont {
        switch self {
        case .heading1:
            return UIFont.DS.heading1

        case .heading2:
            return UIFont.DS.heading2

        case .heading3:
            return UIFont.DS.heading3

        case .heading4:
            return UIFont.DS.heading4

        case .bodySmall(let weight):
            switch weight {
            case .regular:
                return UIFont.DS.Body.small
            case .emphasized:
                return UIFont.DS.Body.Emphasized.small
            }

        case .bodyMedium(let weight):
            switch weight {
            case .regular:
                return UIFont.DS.Body.medium
            case .emphasized:
                return UIFont.DS.Body.Emphasized.medium
            }

        case .bodyLarge(let weight):
            switch weight {
            case .regular:
                return UIFont.DS.Body.large
            case .emphasized:
                return UIFont.DS.Body.Emphasized.large
            }

        case .footnote:
            return UIFont.DS.footnote

        case .caption:
            return UIFont.DS.caption
        }
    }
}

// MARK: - SwiftUI.Text
extension UILabel {
    func style(_ style: TextStyle) -> Self {
        self.font = style.uiFont
        if style.case == .uppercase {
            self.text = self.text?.uppercased()
        }
        return self
    }
}

// MARK: - UIKit.UIFont
fileprivate extension UIFont {
    enum DS {
        static let heading1 = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        static let heading2 = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
        static let heading3 = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .bold)
        static let heading4 = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)

        enum Body {
            static let small = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
            static let medium = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
            static let large = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)

            enum Emphasized {
                static let small = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
                static let medium = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
                static let large = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
            }
        }

        static let footnote = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        static let caption = WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .regular)
    }
}
