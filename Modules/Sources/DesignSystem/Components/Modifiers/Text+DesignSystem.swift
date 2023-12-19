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
public extension Text {
    @ViewBuilder
    func style(_ style: TextStyle) -> some View {
        self.font(style.font)
            .textCase(style.case)
    }
}
