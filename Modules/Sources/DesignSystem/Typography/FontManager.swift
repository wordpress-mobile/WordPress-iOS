import UIKit
import SwiftUI
import CoreText

public enum FontManager {
    public static func registerCustomFonts() {
        _ = register
    }

    // Makes sure it's performed only once.
    private static let register: Void = {
        let fontURLs = Bundle.module
            .urls(forResourcesWithExtension: "otf", subdirectory: nil)
        for fontURL in (fontURLs ?? []) {
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) {
                assertionFailure("failed to register font for: \(fontURL)")
            }
        }
    }()

    public enum FontName {
        case recoleta
    }
}

extension UIFont {
    /// Returns a custom font for the given text style. The returned font is
    /// automatically scaled to support Dynamic Type.
    public static func make(_ font: FontManager.FontName, textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) -> UIFont {
        let descriptor = FontDescriptor.make(font: font, textStyle: .init(textStyle), weight: weight.map(Font.Weight.init))
        let font = makeFont(with: descriptor)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        return metrics.scaledFont(for: font)
    }

    /// - warning: The returned font isn't scaled.
    public static func make(_ font: FontManager.FontName, size: CGFloat, weight: UIFont.Weight? = nil) -> UIFont {
        let descriptor = FontDescriptor.make(font: font, size: size, weight: Font.Weight(weight ?? .regular))
        return makeFont(with: descriptor)
    }

    static func makeFont(with descriptor: FontDescriptor) -> UIFont {
        guard let font = UIFont(name: descriptor.name, size: descriptor.size) else {
            assertionFailure("unsupported font: \(descriptor)")
            return UIFont.preferredFont(forTextStyle: .body)
        }
        return font
    }
}

extension Font {
    public static func make(_ font: FontManager.FontName, textStyle: TextStyle, weight: Weight? = nil) -> Font {
        let descriptor = FontDescriptor.make(font: font, textStyle: textStyle, weight: weight)
        return Font.custom(descriptor.name, size: descriptor.size, relativeTo: textStyle)
    }
}
