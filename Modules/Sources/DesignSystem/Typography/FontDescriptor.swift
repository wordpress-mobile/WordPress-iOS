import UIKit
import SwiftUI

/// The descriptors that match the Apple's specification: https://developer.apple.com/design/human-interface-guidelines/typography
struct FontTextStyleDescriptor {
    var size: CGFloat
    var weight: Font.Weight

    static func make(textStyle: Font.TextStyle) -> FontTextStyleDescriptor {
        switch textStyle {
        case .largeTitle: return .init(size: 34, weight: .regular)
        case .title: return .init(size: 28, weight: .regular)
        case .title2: return .init(size: 22, weight: .regular)
        case .title3: return .init(size: 20, weight: .regular)
        case .headline: return .init(size: 17, weight: .semibold)
        case .body: return .init(size: 17, weight: .regular)
        case .callout: return .init(size: 16, weight: .regular)
        case .subheadline: return .init(size: 15, weight: .regular)
        case .footnote: return .init(size: 13, weight: .regular)
        case .caption: return .init(size: 12, weight: .regular)
        case .caption2: return .init(size: 11, weight: .regular)
        default:
            assertionFailure("unsupported text style: \(textStyle)")
            return .init(size: 17, weight: .regular)
        }
    }
}

struct FontDescriptor: Decodable {
    let size: CGFloat
    let name: String

    static func make(font: FontManager.FontName, textStyle: Font.TextStyle, weight: Font.Weight?) -> FontDescriptor {
        var descriptor = FontTextStyleDescriptor.make(textStyle: textStyle)
        if let weight {
            descriptor.weight = weight // Override the standard weight
        }
        return FontDescriptor.make(font: font, size: descriptor.size, weight: descriptor.weight)

    }

    static func make(font: FontManager.FontName, size: CGFloat, weight: Font.Weight) -> FontDescriptor {
        FontDescriptor(size: size, name: getName(for: font, weight: weight))
    }

    private static func getName(for font: FontManager.FontName, weight: Font.Weight) -> String {
        switch font {
        case .recoleta:
            switch weight {
            case .black: return "Recoleta-Black"
            case .bold: return "Recoleta-Bold"
            case .light: return "Recoleta-Light"
            case .medium: return "Recoleta-Medium"
            case .regular: return "Recoleta-Regular"
            case .semibold: return "Recoleta-Semibold"
            case .thin: return "Recoleta-Thin"
            default:
                assertionFailure("unsupported font: \(font), \(weight)")
                return "Recoleta-Regular"
            }
        }
    }
}

private extension UIFontDescriptor {
    convenience init(_ descriptor: FontDescriptor) {
        self.init(name: descriptor.name, size: descriptor.size)
    }
}

extension Font.TextStyle {
    init(_ style: UIFont.TextStyle) {
        switch style {
        case .largeTitle: self = .largeTitle
        case .title1: self = .title
        case .title2: self = .title2
        case .title3: self = .title3
        case .headline: self = .headline
        case .subheadline: self = .subheadline
        case .body: self = .body
        case .callout: self = .callout
        case .footnote: self = .footnote
        case .caption1: self = .caption
        case .caption2: self = .caption2
        default:
            assertionFailure("unsupported style: \(style)")
            self = .body
        }
    }
}

extension Font.Weight {
    init(_ weight: UIFont.Weight) {
        switch weight {
        case .ultraLight: self = .ultraLight
        case .thin: self = .thin
        case .light: self = .light
        case .regular: self = .regular
        case .medium: self = .medium
        case .semibold: self = .semibold
        case .bold: self = .bold
        case .heavy: self = .heavy
        case .black: self = .black
        default:
            assertionFailure("unsupported weight: \(weight)")
            self = .regular
        }
    }
}
