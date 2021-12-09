import Foundation

final class QuickStartSettings {

    private let userDefaults: UserDefaults

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Quick Start availability

    func isQuickStartAvailable(for blog: Blog) -> Bool {
        return blog.isUserCapableOf(.ManageOptions) &&
            blog.isUserCapableOf(.EditThemeOptions) &&
            !blog.isWPForTeams()
    }

    // MARK: - User Defaults Storage

    func promptWasDismissed(for blog: Blog) -> Bool {
        guard let key = promptWasDismissedKey(for: blog) else {
            return false
        }
        return userDefaults.bool(forKey: key)
    }

    func setPromptWasDismissed(_ value: Bool, for blog: Blog) {
        guard let key = promptWasDismissedKey(for: blog) else {
            return
        }
        userDefaults.set(value, forKey: key)
    }

    private func promptWasDismissedKey(for blog: Blog) -> String? {
        guard let siteID = blog.dotComID?.intValue else {
            return nil
        }
        return "QuickStartPromptWasDismissed-\(siteID)"
    }

}
