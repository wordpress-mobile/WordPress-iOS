import Foundation

/// Helper class for adding and removing the '-wpcom' suffix from themeIds
///
class ThemeIdHelper: NSObject {
    private static let WPComThemesIDSuffix = "-wpcom"

    @objc static func themeIdWithWPComSuffix(_ themeId: String) -> String {
        return themeId.appending(WPComThemesIDSuffix)
    }

    @objc static func themeIdWithWPComSuffixRemoved(_ themeId: String, forBlog blog: Blog) -> String {
        if blog.supports(.customThemes) && themeIdHasWPComSuffix(themeId) {
            // When a WP.com theme is used on a JP site, its themeId is modified to themeId-wpcom,
            // we need to remove this to be able to match it on the theme list
            return String(themeId.dropLast(WPComThemesIDSuffix.count))
        }

        return themeId
    }

    @objc static func themeIdHasWPComSuffix(_ themeId: String) -> Bool {
        return themeId.hasSuffix(WPComThemesIDSuffix)
    }
}
