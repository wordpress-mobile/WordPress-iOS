import Foundation

public final class JetpackInstallPromptSettings {
    private let userDefaults: UserDefaults
    private let showJetpackPluginInstallPrompt: Bool

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard,
         showJetpackPluginInstallPrompt: Bool = AppConfiguration.showJetpackPluginInstallPrompt) {
        self.userDefaults = userDefaults
        self.showJetpackPluginInstallPrompt = showJetpackPluginInstallPrompt
    }

    // MARK: - User Defaults Storage


    /// Determines whether we can show the install prompt
    /// This checks to make sure:
    ///  - The site is not currently a Jetpack / WP.com site
    ///  - The user is an admin
    ///  - And the user hasn't dismissed the prompt before
    /// - Parameter blog: The blog object to check against
    /// - Returns: Whether the prompt can be displayed
    func canDisplay(for blog: Blog) -> Bool {
        guard showJetpackPluginInstallPrompt else {
            return false
        }

        guard let jetpack = blog.jetpack else {
            return false
        }

        return !jetpack.isInstalled && blog.isAdmin && !promptWasDismissed(for: blog)
    }

    func setPromptWasDismissed(_ value: Bool, for blog: Blog) {
        guard let key = dismissedKey(for: blog) else {
            return
        }

        userDefaults.set(value, forKey: key)
    }

    // MARK: - Private: Helpers
    private func promptWasDismissed(for blog: Blog) -> Bool {
        guard let key = dismissedKey(for: blog) else {
            return false
        }

        return userDefaults.bool(forKey: key)
    }

    private func dismissedKey(for blog: Blog) -> String? {
        guard let url = blog.url else {
            return nil
        }

        return "JetpackSelfHostedPromptWasDismissed-\(url)"
    }
}
