import SwiftUI

extension Bundle {
    static let app: Bundle = {
        var url = Bundle.main.bundleURL
        while url.pathExtension != "app" && url.lastPathComponent != "/" {
            url.deleteLastPathComponent()
        }
        guard let appBundle = Bundle(url: url) else { fatalError("Unable to find the parent app bundle") }
        return appBundle
    }()
}

/// This is mostly useful to express *intent* on your API. It does not provide any compile-time guarantee
typealias LocalizedString = String

/// Be sure to use this function instead of `NSLocalizedString` in order to reference localized strings **from the app bundle**.
/// As `NSLocalisedString` by default will look up strings in the current (main) bundle, which could be an App Extension for cases like a Widget
/// but, in order to avoid duplicating our strings accross targets, it is better to make App Extensions / Widgets reference the strings
/// from the `Localizable.strings` files that are hosted the app bundle instead of hosting their own `.strings` file.
///
/// Also, be sure to pass this function name as a custom routine when parsing the code to generate the main `.strings` file,
/// using `genstrings -s AppLocalizedString` to that this helper method is recognized.
func AppLocalizedString(_ key: String, tableName: String? = nil, value: String? = nil, comment: String) -> LocalizedString {
    Bundle.app.localizedString(forKey: key, value: value, table: nil)
}
