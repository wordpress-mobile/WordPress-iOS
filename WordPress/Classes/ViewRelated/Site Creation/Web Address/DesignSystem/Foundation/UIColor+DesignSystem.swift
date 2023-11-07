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
        }

        public enum Background {
            public static let primary = UIColor(named: DesignSystemColorNames.Background.primary)
            public static let secondary = UIColor(named: DesignSystemColorNames.Background.secondary)
            public static let tertiary = UIColor(named: DesignSystemColorNames.Background.tertiary)
            public static let quaternary = UIColor(named: DesignSystemColorNames.Background.quaternary)

            public static var brand: UIColor? {
                if AppConfiguration.isJetpack {
                    return jetpack
                } else {
                    return jetpack // FIXME: WordPress colors
                }
            }

            private static let jetpack = UIColor(named: DesignSystemColorNames.Background.jetpack)
        }

        public enum Border {
            public static let primary = UIColor(named: DesignSystemColorNames.Border.primary)
            public static let secondary = UIColor(named: DesignSystemColorNames.Border.secondary)
            public static let divider = UIColor(named: DesignSystemColorNames.Border.divider)
        }
    }
}
