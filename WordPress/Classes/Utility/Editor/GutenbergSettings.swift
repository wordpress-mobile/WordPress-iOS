import Foundation

/// Takes care of storing and accessing Gutenberg settings.
///
class GutenbergSettings {

    // MARK: - Enabled Editors Keys

    fileprivate let gutenbergEditorEnabledKey = "kUserDefaultsGutenbergEditorEnabled"

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

    func isGutenbergEnabled() -> Bool {
        return database.object(forKey: gutenbergEditorEnabledKey) as? Bool ?? false
    }

    func toggleGutenberg() {
        if isGutenbergEnabled() {
            WPAppAnalytics.track(.appSettingsGutenbergDisabled)
            database.set(false, forKey: gutenbergEditorEnabledKey)
        } else {
            WPAppAnalytics.track(.appSettingsGutenbergEnabled)
            database.set(true, forKey: gutenbergEditorEnabledKey)
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
            return isGutenbergEnabled()
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
        return GutenbergSettings().isGutenbergEnabled()
    }
}
