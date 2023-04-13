import SwiftUI

extension Color {
    enum DS {
        enum Foreground {
            static let primary = Color("foregroundPrimary")
            static let secondary = Color("foregroundSecondary")
            static let tertiary = Color("foregroundTertiary")
        }

        enum Background {
            static let primary = Color("backgroundPrimary")
            static let secondary = Color("backgroundSecondary")
            static let tertiary = Color("backgroundTertiary")
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

// Replica of the `Color` structure
extension UIColor {
    enum DS {
        enum Foreground {
            static let primary = UIColor(Color.DS.Foreground.primary)
            static let secondary = UIColor(Color.DS.Foreground.secondary)
            static let tertiary = UIColor(Color.DS.Foreground.tertiary)
        }

        enum Background {
            static let primary = UIColor(Color.DS.Background.primary)
            static let secondary = UIColor(Color.DS.Background.secondary)
            static let tertiary = UIColor(Color.DS.Background.tertiary)
        }

        enum Theme {
            static let primary = UIColor(Color.DS.Theme.primary)
        }
    }
}
