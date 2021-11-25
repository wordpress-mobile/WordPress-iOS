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

typealias LocalizedString = String // Useful only to express intent on your API; does not provide any compile-time guarantee

func AppLocalizedString(_ key: String, value: String?, comment: String) -> LocalizedString {
    Bundle.app.localizedString(forKey: key, value: value, table: nil)
}
