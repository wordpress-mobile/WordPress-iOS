import UIKit

// MARK: - UIKit.UIFont: TextStyle
public extension TextStyle {
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
public extension UILabel {
    func setStyle(_ style: TextStyle) {
        self.font = style.uiFont
        if style.case == .uppercase {
            self.text = self.text?.uppercased()
        }
    }
}

// MARK: - UIKit.UIFont
fileprivate extension UIFont {
    enum DS {
        static let heading1 = DynamicFontHelper.fontForTextStyle(.largeTitle, fontWeight: .bold)
        static let heading2 = DynamicFontHelper.fontForTextStyle(.title1, fontWeight: .bold)
        static let heading3 = DynamicFontHelper.fontForTextStyle(.title2, fontWeight: .bold)
        static let heading4 = DynamicFontHelper.fontForTextStyle(.title3, fontWeight: .semibold)

        enum Body {
            static let small = DynamicFontHelper.fontForTextStyle(.subheadline, fontWeight: .regular)
            static let medium = DynamicFontHelper.fontForTextStyle(.callout, fontWeight: .regular)
            static let large = DynamicFontHelper.fontForTextStyle(.body, fontWeight: .regular)

            enum Emphasized {
                static let small = DynamicFontHelper.fontForTextStyle(.subheadline, fontWeight: .semibold)
                static let medium = DynamicFontHelper.fontForTextStyle(.callout, fontWeight: .semibold)
                static let large = DynamicFontHelper.fontForTextStyle(.body, fontWeight: .semibold)
            }
        }

        static let footnote = DynamicFontHelper.fontForTextStyle(.footnote, fontWeight: .regular)
        static let caption = DynamicFontHelper.fontForTextStyle(.caption1, fontWeight: .regular)
    }
}

private enum DynamicFontHelper {
    static func fontForTextStyle(_ style: UIFont.TextStyle, fontWeight weight: UIFont.Weight) -> UIFont {
        /// WORKAROUND: Some font weights scale up well initially but they don't scale up well if dynamic type
        ///     is changed in real time.  Creating a scaled font offers an alternative solution that works well
        ///     even in real time.
        let weightsThatNeedScaledFont: [UIFont.Weight] = [.black, .bold, .heavy, .semibold]

        guard !weightsThatNeedScaledFont.contains(weight) else {
            return scaledFont(for: style, weight: weight)
        }

        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)

        let traits = [UIFontDescriptor.TraitKey.weight: weight]
        fontDescriptor = fontDescriptor.addingAttributes([.traits: traits])

        return UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
    }

    static func scaledFont(for style: UIFont.TextStyle, weight: UIFont.Weight, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let fontDescriptorWithDesign = fontDescriptor.withDesign(design) ?? fontDescriptor
        let traits = [UIFontDescriptor.TraitKey.weight: weight]
        let finalDescriptor = fontDescriptorWithDesign.addingAttributes([.traits: traits])

        return UIFont(descriptor: finalDescriptor, size: finalDescriptor.pointSize)
    }
}
