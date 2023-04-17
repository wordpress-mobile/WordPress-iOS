import UIKit

/// Replica of the `Color` structure
/// The reason for not using the `Color` intializer of `UIColor` is that
/// it has dubious effects. Also the doc advises against it.
/// Even though `UIColor(SwiftUI.Color)` keeps the adaptability for color theme,
/// accessing to light or dark variants specifically via trait collection does not return the right values
/// if the color is initialized as such. Probably one of the reasons why they advise against it.
/// To make these values non-optional, we use `Color` versions as fallback.
extension UIColor {
    enum DS {
        enum Foreground {
            static let primary = UIColor(named: "foregroundPrimary")
            static let secondary = UIColor(named: "foregroundSecondary")
            static let tertiary = UIColor(named: "foregroundTertiary")
            static let quaternary = UIColor(named: "backgroundQuaternary")
        }

        enum Background {
            static let primary = UIColor(named: "backgroundPrimary")
            static let secondary = UIColor(named: "backgroundSecondary")
            static let tertiary = UIColor(named: "backgroundTertiary")
            static let quaternary = UIColor(named: "backgroundQuaternary")
        }

        enum Border {
            static let primary = Color("borderPrimary")
            static let secondary = Color("borderSecondary")
            static let divider = Color("borderDivider")
        }

        enum Theme {
            static var primary: UIColor? {
                if AppConfiguration.isJetpack {
                    return jetpack
                } else {
                    return jetpack // FIXME: WordPress colors
                }
            }

            private static let jetpack = UIColor(named: "themeJetpack")
        }
    }
}
