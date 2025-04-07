import Foundation
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
}
