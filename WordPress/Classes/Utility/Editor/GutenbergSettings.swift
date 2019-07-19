import Foundation

/// Takes care of storing and accessing Gutenberg settings.
///
class GutenbergSettings {

    // MARK: - Enabled Editors Keys
    enum Key {
        static let enabled = "kUserDefaultsGutenbergEditorEnabled"
    }

    // MARK: - Internal variables
    fileprivate let database: KeyValueDatabase

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
    }

    convenience init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }

    // MARK: Public accessors

    /// True if gutenberg editor is currently enabled
    var isGutenbergEnabled: Bool {
        get {
            return database.bool(forKey: Key.enabled)
        }
        set(isEnabled) {
            if isGutenbergEnabled != isEnabled {
                trackSettingChange(to: isEnabled)
            }
            database.set(isEnabled, forKey: Key.enabled)
        }
    }

    /// True if gutenberg editor has been enabled at least once
    var wasGutenbergEnabledOnce: Bool {
        return database.object(forKey: Key.enabled) != nil
    }

    private func trackSettingChange(to isEnabled: Bool) {
        let stat: WPAnalyticsStat = isEnabled ? .appSettingsGutenbergEnabled : .appSettingsGutenbergDisabled
        WPAppAnalytics.track(stat)
        WPAnalytics.refreshMetadata()
    }

    func shouldAutoenableGutenberg(for post: AbstractPost) -> Bool {
        return  post.containsGutenbergBlocks() && !wasGutenbergEnabledOnce
    }

    // MARK: - Gutenberg Choice Logic

    /// Call this method to know if Gutenberg must be used for the specified post.
    ///
    /// - Parameters:
    ///     - post: the post that will be edited.
    ///
    /// - Returns: true if the post must be edited with Gutenberg.
    ///
    func mustUseGutenberg(for post: AbstractPost) -> Bool {
        if post.isContentEmpty() {
            // It's a new post
            return isGutenbergEnabled
        } else {
            // It's an existing post
            return post.containsGutenbergBlocks()
        }
    }
}

@objc(GutenbergSettings)
class GutenbergSettingsBridge: NSObject {
    @objc
    static func isGutenbergEnabled() -> Bool {
        return GutenbergSettings().isGutenbergEnabled
    }
}
