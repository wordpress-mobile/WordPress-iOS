import SwiftUI

// MARK: - SwiftUI.Font: TextStyle
extension TextStyle {
    var font: Font {
        switch self {
        case .heading1:
            return Font.DS.heading1

        case .heading2:
            return Font.DS.heading2

        case .heading3:
            return Font.DS.heading3

        case .heading4:
            return Font.DS.heading4

        case .bodySmall(let weight):
            switch weight {
            case .regular:
                return Font.DS.Body.small
            case .emphasized:
                return Font.DS.Body.Emphasized.small
            }

        case .bodyMedium(let weight):
            switch weight {
            case .regular:
                return Font.DS.Body.medium
            case .emphasized:
                return Font.DS.Body.Emphasized.medium
            }

        case .bodyLarge(let weight):
            switch weight {
            case .regular:
                return Font.DS.Body.large
            case .emphasized:
                return Font.DS.Body.Emphasized.large
            }

        case .footnote:
            return Font.DS.footnote

        case .caption:
            return Font.DS.caption
        }
    }

    var `case`: Text.Case? {
        switch self {
        case .caption:
            return .uppercase
        default:
            return nil
        }
    }
}

// MARK: - SwiftUI.Text
extension Text {
    @ViewBuilder
    func style(_ style: TextStyle) -> some View {
        self.font(style.font)
            .textCase(style.case)
    }
}

// MARK: - SwiftUI.Font
fileprivate extension Font {
    enum DS {
        static let heading1 = Font.largeTitle
        static let heading2 = Font.title
        static let heading3 = Font.title2
        static let heading4 = Font.title3

        enum Body {
            static let small = Font.body
            static let medium = Font.callout
            static let large = Font.subheadline

            enum Emphasized {
                static let small = Body.small.weight(.semibold)
                static let medium = Body.medium.weight(.semibold)
                static let large = Body.large.weight(.semibold)
            }
        }

        static let footnote = Font.footnote
        static let caption = Font.caption
    }
}
