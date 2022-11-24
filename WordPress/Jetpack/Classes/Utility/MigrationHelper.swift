import Foundation

struct MigrationHelper {
    static func isWordPressInstalled() -> Bool {
        guard let wordPressScheme = URL(string: "wordpress://") else {
            return false
        }
        return UIApplication.shared.canOpenURL(wordPressScheme)
    }
}
