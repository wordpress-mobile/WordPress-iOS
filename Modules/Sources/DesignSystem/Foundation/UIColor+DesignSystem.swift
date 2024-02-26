import UIKit

/// Replica of the `Color` structure
/// The reason for not using the `Color` intializer of `UIColor` is that
/// it has dubious effects. Also the doc advises against it.
/// Even though `UIColor(SwiftUI.Color)` keeps the adaptability for color theme,
/// accessing to light or dark variants specifically via trait collection does not return the right values
/// if the color is initialized as such. Probably one of the reasons why they advise against it.
/// To make these values non-optional, we use `Color` versions as fallback.
public extension UIColor {
    enum DS {
        public enum Foreground {
            public static let primary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.primary)
            public static let secondary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.secondary)
            public static let tertiary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.tertiary)
            public static let quaternary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.quaternary)
            public static let success = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.success)
            public static let warning = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.warning)
            public static let error = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.error)

            public static func brand(isJetpack: Bool) -> UIColor? {
                isJetpack ? jetpack : wordPress
            }

            private static let jetpack = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.jetpack)
            private static let wordPress = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.wordPress)
        }

        public enum Background {
            public static let primary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.primary)
            public static let secondary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.secondary)
            public static let tertiary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.tertiary)
            public static let quaternary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.quaternary)

            public static func brand(isJetpack: Bool) -> UIColor? {
                isJetpack ? jetpack : wordPress
            }

            private static let jetpack = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.jetpack)
            private static let wordPress = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.wordPress)
        }

        private static func colorWithModuleBundle(colorName: String) -> UIColor {
            UIColor(named: colorName, in: .module, compatibleWith: .current) ?? .clear
        }
    }
}
