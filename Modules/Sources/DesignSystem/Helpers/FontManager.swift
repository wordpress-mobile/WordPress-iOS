import UIKit
import CoreText

public final class FontManager {
    public static func registerCustomFonts() {
        let fontURLs = Bundle.module
            .urls(forResourcesWithExtension: "otf", subdirectory: nil)
        for fontURL in (fontURLs ?? []) {
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) {
                assertionFailure("failed to register font for: \(fontURL)")
            }
        }
    }

    /// Returns a custom font for the given text style. The returned font is
    /// automatically scaled to support Dynamic Type.
    public static func font(_ font: CustomFont, textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) -> UIFont {
        var styleDesctiptor = FontTextStyleDescriptor.make(textStyle: textStyle)
        if let weight {
            styleDesctiptor.weight = weight // Override the standard weight
        }
        let fontDescriptor = FontDescriptor.make(font: font, descriptor: styleDesctiptor)

        guard let font = UIFont(name: fontDescriptor.name, size: fontDescriptor.size) else {
            assertionFailure("unsupported font: \(font), \(textStyle)")
            return UIFont.preferredFont(forTextStyle: textStyle)
        }
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        return metrics.scaledFont(for: font)
    }
}

public enum CustomFont {
    case recoleta
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

    static func make(font: CustomFont, descriptor: FontTextStyleDescriptor) -> FontDescriptor {
        FontDescriptor.make(font: font, size: descriptor.size, weight: descriptor.weight)
    }

    static func make(font: CustomFont, size: CGFloat, weight: UIFont.Weight) -> FontDescriptor {
        switch font {
        case .recoleta:
            switch weight {
            case .black: return FontDescriptor(size: size, name: "RecoletaBlack")
            case .bold: return FontDescriptor(size: size, name: "RecoletaBold")
            case .light: return FontDescriptor(size: size, name: "RecoletaLight")
            case .medium: return FontDescriptor(size: size, name: "RecoletaMedium")
            case .regular: return FontDescriptor(size: size, name: "RecoletaRegular")
            case .semibold: return FontDescriptor(size: size, name: "RecoletaSemiBold")
            case .thin: return FontDescriptor(size: size, name: "RecoletaThin")
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
