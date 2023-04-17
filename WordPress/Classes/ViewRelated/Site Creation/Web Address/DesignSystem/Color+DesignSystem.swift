import SwiftUI

/// Design System Color extensions. Keep it in sync with its sibling file `UIColor+DesignSystem`
/// to support borth API's equally.
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

        enum Border {
            static let primary = Color("borderPrimary")
            static let secondary = Color("borderSecondary")
            static let divider = Color("borderDivider")
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
