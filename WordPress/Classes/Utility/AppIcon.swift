import UIKit

/// Encapsulates a custom icon used by the app and provides some convenience
/// methods around using custom icons.
///
struct AppIcon {
    let name: String

    /// Icons with a white background require a border when displayed so their edges remain visible.
    let isBordered: Bool

    /// Legacy icons are the original set of custom icons available in the app. They have been superseded
    /// by a newer style of icon, but are still provided for compatibility and for users who prefer them.
    let isLegacy: Bool

    var displayName: String {
        return name.replacingMatches(of: " Classic", with: "")
    }

    var imageName: String {
        let lowered = name.lowercased().replacingMatches(of: " ", with: "-")
        return "\(lowered)-\(Constants.imageBaseName)"
    }

    static var isUsingCustomIcon: Bool {
        return UIApplication.shared.alternateIconName != nil
    }

    /// The image file name of the current icon used by the app, whether custom or default.
    static var currentOrDefaultIconName: String {
        guard AppConfiguration.allowsCustomAppIcons else {
            return iconNameFromBundle()
        }

        return currentOrDefaultIcon.imageName
    }

    /// An `AppIcon` instance representing the current icon used by the app, whether custom or default.
    static private var currentOrDefaultIcon: AppIcon {
        if let name = UIApplication.shared.alternateIconName {
            return allIcons.first(where: { $0.name == name }) ?? defaultIcon
        } else {
            return defaultIcon
        }
    }

    /// An `AppIcon` instance representing the default icon for the app.
    static var defaultIcon: AppIcon {
        return AppIcon(name: AppIcon.defaultIconName,
                       isBordered: false,
                       isLegacy: false)
    }

    /// An array of `AppIcons` representing all possible custom icons that can be used by the app.
    static var allIcons: [AppIcon] {
        guard let bundleDict = Bundle.main.object(forInfoDictionaryKey: Constants.infoPlistBundleIconsKey) as? [String: Any],
              let iconDict = bundleDict[Constants.infoPlistAlternateIconsKey] as? [String: Any] else {
            return [defaultIcon]
        }

        let customIcons = iconDict.compactMap { (key, value) -> AppIcon? in
            guard let value = value as? [String: Any] else {
                return nil
            }

            let isBordered = value[Constants.infoPlistRequiresBorderKey] as? Bool == true
            let isLegacy = value[Constants.infoPlistLegacyIconKey] as? Bool == true
            return AppIcon(name: key, isBordered: isBordered, isLegacy: isLegacy)
        }

        return [defaultIcon] + customIcons
    }

    /// The app's default icon filename returned from the app's info plist.
    private static func iconNameFromBundle() -> String {
        guard let icons =
                Bundle.main.infoDictionary?[Constants.infoPlistBundleIconsKey] as? [String: Any],
              let primaryIcon = icons[Constants.infoPlistPrimaryIconKey] as? [String: Any],
              let iconFiles = primaryIcon[Constants.infoPlistIconFilesKey] as? [String] else {
                  return ""
              }

        return iconFiles.last ?? ""
    }

    private enum Constants {
        static let infoPlistBundleIconsKey    = "CFBundleIcons"
        static let infoPlistPrimaryIconKey    = "CFBundlePrimaryIcon"
        static let infoPlistAlternateIconsKey = "CFBundleAlternateIcons"
        static let infoPlistIconFilesKey      = "CFBundleIconFiles"
        static let infoPlistRequiresBorderKey = "WPRequiresBorder"
        static let infoPlistLegacyIconKey     = "WPLegacyIcon"
        static let imageBaseName              = "icon-app-60x60"
    }

    static let defaultIconName = "Blue"
    static let defaultLegacyIconName = "WordPress"
}
