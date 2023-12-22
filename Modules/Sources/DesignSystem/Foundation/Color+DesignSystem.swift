import SwiftUI

/// Design System Color extensions. Keep it in sync with its sibling file `UIColor+DesignSystem`
/// to support borth API's equally.
public extension Color {
    enum DS {
        public enum Foreground {
            public static let primary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.primary)
            public static let secondary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.secondary)
            public static let tertiary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.tertiary)
            public static let quaternary = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.quaternary)
            public static let success = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.success)
            public static let warning = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.warning)
            public static let error = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.error)

            public static func brand(isJetpack: Bool) -> Color {
                return isJetpack ? jetpack : wordPress
            }

            private static let jetpack = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.jetpack)
            private static let wordPress = colorWithModuleBundle(colorName: DesignSystemColorNames.Foreground.wordPress)
        }

        public enum Background {
            public static let primary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.primary)
            public static let secondary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.secondary)
            public static let tertiary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.tertiary)
            public static let quaternary = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.quaternary)

            public static func brand(isJetpack: Bool) -> Color {
                return isJetpack ? jetpack : wordPress
            }

            private static let jetpack = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.jetpack)
            private static let wordPress = colorWithModuleBundle(colorName: DesignSystemColorNames.Background.wordPress)
        }

        public static let divider = colorWithModuleBundle(colorName: DesignSystemColorNames.divider)

        private static func colorWithModuleBundle(colorName: String) -> Color {
            Color(colorName, bundle: .module)
        }
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
