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
            public static let primary = UIColor(named: DesignSystemColorNames.Foreground.primary)
            public static let secondary = UIColor(named: DesignSystemColorNames.Foreground.secondary)
            public static let tertiary = UIColor(named: DesignSystemColorNames.Foreground.tertiary)
            public static let quaternary = UIColor(named: DesignSystemColorNames.Foreground.quaternary)
            public static let success = UIColor(named: DesignSystemColorNames.Foreground.success)
            public static let warning = UIColor(named: DesignSystemColorNames.Foreground.warning)
            public static let error = UIColor(named: DesignSystemColorNames.Foreground.error)

            public static func brand(isJetpack: Bool) -> UIColor? {
                isJetpack ? jetpack : wordPress
            }

            private static let jetpack = UIColor(named: DesignSystemColorNames.Foreground.jetpack)
            private static let wordPress = UIColor(named: DesignSystemColorNames.Foreground.wordPress)
        }

        public enum Background {
            public static let primary = UIColor(named: DesignSystemColorNames.Background.primary)
            public static let secondary = UIColor(named: DesignSystemColorNames.Background.secondary)
            public static let tertiary = UIColor(named: DesignSystemColorNames.Background.tertiary)
            public static let quaternary = UIColor(named: DesignSystemColorNames.Background.quaternary)

            public static func brand(isJetpack: Bool) -> UIColor? {
                isJetpack ? jetpack : wordPress
            }

            private static let jetpack = UIColor(named: DesignSystemColorNames.Background.jetpack)
            private static let wordPress = UIColor(named: DesignSystemColorNames.Background.wordPress)
        }

        public static let divider = UIColor(named: DesignSystemColorNames.divider)
    }
}
