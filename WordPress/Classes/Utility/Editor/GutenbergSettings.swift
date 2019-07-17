import Foundation

/// Takes care of storing and accessing Gutenberg settings.
///
class GutenbergSettings {

    // MARK: - Enabled Editors Keys
    enum Key {
        static let enabled = "kUserDefaultsGutenbergEditorEnabled"
        // This key is already used to auto-enable gutenberg upon showing the informative dialog,
        // so we need to keep it as it is to get the value from previous users and avoid showing the dialog again.
        static let enabledOnce = "Gutenberg.InformativeDialog"
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
    private(set) var isGutenbergEnabled: Bool {
        get {
            return database.bool(forKey: Key.enabled)
        }
        set(enabled) {
            if enabled {
                wasGutenbergEnabledOnce = true
            }
            database.set(enabled, forKey: Key.enabled)
        }
    }

    /// True if gutenberg editor has been enabled at least once
    var wasGutenbergEnabledOnce: Bool {
        get {
            return isGutenbergEnabled || database.bool(forKey: Key.enabledOnce)
        }
        set {
            database.set(newValue, forKey: Key.enabledOnce)
        }
    }

    func shouldAutoenableGutenberg(for post: AbstractPost) -> Bool {
        return  post.containsGutenbergBlocks() && !wasGutenbergEnabledOnce
    }

    func setGutenbergEnabledIfNeeded() {
        if isGutenbergEnabled == false {
            toggleGutenberg()
        }
    }

    func toggleGutenberg() {
        if isGutenbergEnabled {
            WPAppAnalytics.track(.appSettingsGutenbergDisabled)
            isGutenbergEnabled = false
        } else {
            WPAppAnalytics.track(.appSettingsGutenbergEnabled)
            isGutenbergEnabled = true
        }
        WPAnalytics.refreshMetadata()
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
