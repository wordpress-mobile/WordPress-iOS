import Foundation
import CoreData
import WordPressShared

@objc(Theme)
public class Theme: NSManagedObject {
    private static let adminUrlCustomize = "customize.php?theme=%@&hide_close=true"
    private static let urlDemoParameters = "?demo=true&iframe=true&theme_preview=true"
    private static let urlSupport = "https://wordpress.com/themes/%@/support/?preview=true&iframe=true"
    private static let urlDetails = "https://wordpress.com/themes/%@/%@/?preview=true&iframe=true"

    public func detailsUrl() -> String? {
        if custom {
            return themeUrl
        }
        if let homeUrl = blog?.homeURL?.hostname() {
            return String(format: Theme.urlDetails, homeUrl, themeId ?? "")
        }
        return nil
    }

    public func supportUrl() -> String {
        String(format: Theme.urlSupport, themeId ?? "")
    }

    public func viewUrl() -> String {
        if let demoUrl {
            return demoUrl + Theme.urlDemoParameters
        }
        return ""
    }

    public func isCurrentTheme() -> Bool {
        blog?.currentThemeId == themeId
    }

    public func isPremium() -> Bool {
        premium?.boolValue ?? false
    }

    public func hasDetailsURL() -> Bool {
        guard let url = detailsUrl() else { return false }
        return !url.isEmpty
    }
}
