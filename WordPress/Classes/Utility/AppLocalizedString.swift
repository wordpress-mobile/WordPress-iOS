import SwiftUI


extension Bundle {
    /// Returns the `Bundle` for the host `.app`.
    ///
    /// - If this is called from code already located in the main app's bundle or from a Pod/Framework,
    ///   this will return the same as `Bundle.main`, aka the bundle of the app itself.
    /// - If this is called from an App Extension (Widget, ShareExtension, etc), this will return the bundle of the
    ///   main app hosting said App Extension (while `Bundle.main` would return the App Extension itself)
    ///
    /// This is particularly useful to reference a resource or string bundled inside the app from an App Extension / Widget.
    ///
    /// - Note:
    ///   In the context of Unit Tests this will return the Test Harness (aka Test Host) app, since that is the app running said tests.
    ///
    static let app: Bundle = {
        var url = Bundle.main.bundleURL
        while url.pathExtension != "app" && url.lastPathComponent != "/" {
            url.deleteLastPathComponent()
        }
        guard let appBundle = Bundle(url: url) else { fatalError("Unable to find the parent app bundle") }
        return appBundle
    }()
}

/// Use this to express *intent* on your API that the string you are manipulating / returning is intended to already be localized
/// and its value to have been provided via a call to `NSLocalizedString` or `AppLocalizedString`.
///
/// Semantically speaking, a method taking or returning a `LocalizedString` is signaling that you can display said UI string
/// to the end user, without the need to be treated as a key to be localized. The string is expected to already have been localized
/// at that point of the code, via a call to `NSLocalizedString`, `AppLocalizedString` or similar upstream in the code.
///
/// - Note: Remember though that, as a `typealias`, this won't provide any compile-time guarantee.
typealias LocalizedString = String

/// Use this function instead of `NSLocalizedString` to reference localized strings **from the app bundle** – especially
/// when using localized strings from the code of an app extension.
///
/// You should use this `AppLocalizedString` method in place of `NSLocalizedString` especially when calling it
/// from App Extensions and Widgets, in order to reference strings whose localization live in the app bundle's `.strings` file
/// (rather than the AppExtension's own bundle).
///
/// In order to avoid duplicating our strings accross targets, and make our localization process & tooling easier, we keep all
/// localized `.strings` in the app's bundle (and don't have a `.strings` file in the App Extension targets themselves);
/// then we make those App Extensions & Widgets reference the strings from the `Localizable.strings` files
/// hosted in the app bundle itself – which is when this helper method is helpful.
///
/// - Note:
///   Tooling: Be sure to pass this function's name as a custom routine when parsing the code to generate the main `.strings` file,
///   using `genstrings -s AppLocalizedString`, so that this helper method is recognized. You will also have to
///   exclude this very file from being parsed by `genstrings`, so that it won't accidentally misinterpret that routine/function definition
///   below as a call site and generate an error because of it.
///
/// - Parameters:
///   - key: An identifying value used to reference a localized string.
///   - tableName: The basename of the `.strings` file **in the app bundle** containing
///     the localized values. If `tableName` is `nil`, the `Localizable` table is used.
///   - value: The English/default copy for the string. This is the user-visible string that the
///     translators will use as original to translate, and also the string returned when the localized string for
///     `key` cannot be found in the table. If `value` is `nil` or empty, `key` would be returned instead.
///   - comment: A note to the translator describing the context where the localized string is presented to the user.
///
/// - Returns: A localized version of the string designated by `key` in the table identified by `tableName`.
///   If the localized string for `key` cannot be found within the table, `value` is returned.
///   (However, `key` is returned instead when `value` is `nil` or the empty string).
func AppLocalizedString(_ key: String, tableName: String? = nil, value: String? = nil, comment: String) -> LocalizedString {
    Bundle.app.localizedString(forKey: key, value: value, table: nil)
}
