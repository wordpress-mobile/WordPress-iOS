import SwiftUI

extension Color {
    enum DS {
        enum Foreground {
            static let primary = Color("foregroundPrimary")
            static let secondary = Color("foregroundSecondary")
            static let tertiary = Color("foregroundTertiary")
            static let quaternary = Color("backgroundQuaternary")
        }

        enum Background {
            static let primary = Color("backgroundPrimary")
            static let secondary = Color("backgroundSecondary")
            static let tertiary = Color("backgroundTertiary")
            static let quaternary = Color("backgroundQuaternary")
        }

        enum Theme {
            static var primary: Color {
                if AppConfiguration.isJetpack {
                    return jetpack
                } else {
                    return jetpack // FIXME: WordPress colors
                }
            }

            private static let jetpack = Color("themeJetpack")
        }
    }
}

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
