import UIKit
import SwiftUI
import CoreText

public enum FontManager {
    public static func registerCustomFonts() {
        let fontURLs = Bundle.module
            .urls(forResourcesWithExtension: "otf", subdirectory: nil)
        for fontURL in (fontURLs ?? []) {
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) {
                assertionFailure("failed to register font for: \(fontURL)")
            }
        }
    }

    public enum FontName {
        case recoleta
    }
}

extension UIFont {
    /// Returns a custom font for the given text style. The returned font is
    /// automatically scaled to support Dynamic Type.
    public static func make(_ font: FontManager.FontName, textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) -> UIFont {
        let descriptor = FontDescriptor.make(font: font, textStyle: textStyle, weight: weight)
        let font = makeFont(with: descriptor)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        return metrics.scaledFont(for: font)
    }

    /// - warning: The returned font isn't scaled.
    public static func make(_ font: FontManager.FontName, size: CGFloat, weight: UIFont.Weight? = nil) -> UIFont {
        let descriptor = FontDescriptor.make(font: font, size: size, weight: weight ?? .regular)
        return makeFont(with: descriptor)
    }
}

private extension UIFont {
    private static func makeFont(with descriptor: FontDescriptor) -> UIFont {
        guard let font = UIFont(name: descriptor.name, size: descriptor.size) else {
            assertionFailure("unsupported font: \(descriptor)")
            return UIFont.preferredFont(forTextStyle: .body)
        }
        return font
    }
}

extension Font {
    public static func make(_ font: FontManager.FontName, textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) -> Font {
        Font(UIFont.make(font, textStyle: textStyle, weight: weight) as CTFont)
    }
}

/// The descriptors that match the Apple's specification: https://developer.apple.com/design/human-interface-guidelines/typography
private struct FontTextStyleDescriptor {
    var size: CGFloat
    var weight: UIFont.Weight

    static func make(textStyle: UIFont.TextStyle) -> FontTextStyleDescriptor {
        switch textStyle {
        case .largeTitle: return .init(size: 34, weight: .regular)
        case .title1: return .init(size: 28, weight: .regular)
        case .title2: return .init(size: 22, weight: .regular)
        case .title3: return .init(size: 20, weight: .regular)
        case .headline: return .init(size: 17, weight: .semibold)
        case .body: return .init(size: 17, weight: .regular)
        case .callout: return .init(size: 16, weight: .regular)
        case .subheadline: return .init(size: 15, weight: .regular)
        case .footnote: return .init(size: 13, weight: .regular)
        case .caption1: return .init(size: 12, weight: .regular)
        case .caption2: return .init(size: 11, weight: .regular)
        default:
            assertionFailure("unsupported text style: \(textStyle)")
            return .init(size: 17, weight: .regular)
        }
    }
}

private struct FontDescriptor: Decodable {
    let size: CGFloat
    let name: String

    static func make(font: FontManager.FontName, textStyle: UIFont.TextStyle, weight: UIFont.Weight?) -> FontDescriptor {
        var desctiptor = FontTextStyleDescriptor.make(textStyle: textStyle)
        if let weight {
            desctiptor.weight = weight // Override the standard weight
        }
        return FontDescriptor.make(font: font, size: desctiptor.size, weight: desctiptor.weight)

    }

    static func make(font: FontManager.FontName, size: CGFloat, weight: UIFont.Weight) -> FontDescriptor {
        switch font {
        case .recoleta:
            switch weight {
            case .black: return FontDescriptor(size: size, name: "Recoleta-Black")
            case .bold: return FontDescriptor(size: size, name: "Recoleta-Bold")
            case .light: return FontDescriptor(size: size, name: "Recoleta-Light")
            case .medium: return FontDescriptor(size: size, name: "Recoleta-Medium")
            case .regular: return FontDescriptor(size: size, name: "Recoleta-Regular")
            case .semibold: return FontDescriptor(size: size, name: "Recoleta-Semibold")
            case .thin: return FontDescriptor(size: size, name: "Recoleta-Thin")
            default:
                assertionFailure("unsupported font: \(font), \(size), \(weight)")
                return FontDescriptor(size: size, name: "RecoletaRegular")
            }
        }
    }
}

private extension UIFontDescriptor {
    convenience init(_ descriptor: FontDescriptor) {
        self.init(name: descriptor.name, size: descriptor.size)
    }
}
