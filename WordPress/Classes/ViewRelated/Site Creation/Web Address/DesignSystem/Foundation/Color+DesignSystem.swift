import SwiftUI

/// Design System Color extensions. Keep it in sync with its sibling file `UIColor+DesignSystem`
/// to support borth API's equally.
public extension Color {
    enum DS {
        public enum Foreground {
            public static let primary = Color(DesignSystemColorNames.Foreground.primary)
            public static let secondary = Color(DesignSystemColorNames.Foreground.secondary)
            public static let tertiary = Color(DesignSystemColorNames.Foreground.tertiary)
            public static let quaternary = Color(DesignSystemColorNames.Foreground.quaternary)
            public static let success = Color(DesignSystemColorNames.Foreground.success)
            public static let warning = Color(DesignSystemColorNames.Foreground.warning)
            public static let error = Color(DesignSystemColorNames.Foreground.error)

            public static var brand: Color {
                if AppConfiguration.isJetpack {
                    return jetpack
                } else {
                    return wordPress
                }
            }

            private static let jetpack = Color(DesignSystemColorNames.Foreground.jetpack)
            private static let wordPress = Color(DesignSystemColorNames.Foreground.wordPress)
        }

        public enum Background {
            public static let primary = Color(DesignSystemColorNames.Background.primary)
            public static let secondary = Color(DesignSystemColorNames.Background.secondary)
            public static let tertiary = Color(DesignSystemColorNames.Background.tertiary)
            public static let quaternary = Color(DesignSystemColorNames.Background.quaternary)

            public static var brand: Color {
                if AppConfiguration.isJetpack {
                    return jetpack
                } else {
                    return wordPress
                }
            }

            private static let jetpack = Color(DesignSystemColorNames.Background.jetpack)
            private static let wordPress = Color(DesignSystemColorNames.Background.wordPress)
        }

        public static let divider = Color(DesignSystemColorNames.divider)
    }
}

/// Once we move Design System to its own module, we should keep this `internal`
/// as we don't need to expose it to the application module
internal enum DesignSystemColorNames {
    internal enum Foreground {
        internal static let primary = "foregroundPrimary"
        internal static let secondary = "foregroundSecondary"
        internal static let tertiary = "foregroundTertiary"
        internal static let quaternary = "foregroundQuaternary"
        internal static let success = "success"
        internal static let warning = "warning"
        internal static let error = "error"
        internal static let jetpack = "foregroundBrandJP"
        internal static let wordPress = "foregroundBrandWP"
    }

    internal enum Background {
        internal static let primary = "backgroundPrimary"
        internal static let secondary = "backgroundSecondary"
        internal static let tertiary = "backgroundTertiary"
        internal static let quaternary = "backgroundQuaternary"
        internal static let jetpack = "backgroundBrandJP"
        internal static let wordPress = "backgroundBrandWP"
    }

    internal static let divider = "divider"
}
