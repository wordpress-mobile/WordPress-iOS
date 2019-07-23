import Foundation

private let MIN_WPCOM_USER_ID_TO_DEFAULT_GB: Int = 149287441

/// Takes care of storing and accessing Gutenberg settings.
///
class GutenbergSettings {
    // MARK: - Enabled Editors Keys
    enum Key {
        static let enabledOnce = "kUserDefaultsGutenbergEditorEnabled"
    }

    // MARK: - Internal variables
    fileprivate let database: KeyValueDatabase

    let context = Environment.current.contextManager.mainContext

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
    }

    convenience init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }

    /// Get the deprecated app-wide value of gutenberg enabled.
    /// This is useful for the local to remote migration, and for the global to per-site migration.
    private var oldAppWideIsGutenbergEnabled: Bool {
        return database.bool(forKey: Key.enabledOnce)
    }

    // MARK: Public accessors

    /// Sets gutenberg enabled state locally for the given site.
    ///
    /// - Parameters:
    ///   - isEnabled: Enabled state to set
    ///   - blog: The site to set the gutenberg enabled state
    func setGutenbergEnabled(_ isEnabled: Bool, for blog: Blog) {
        let selectedEditor: MobileEditor = isEnabled ? .gutenberg : .aztec
        guard shouldUpdateSettings(with: selectedEditor, for: blog) else {
            return
        }

        if blog.isGutenbergEnabled != isEnabled {
            trackSettingChange(to: isEnabled)
        }

        if isEnabled {
            /// After the migrations are finished, this value will be used to decide if we should auto-enable gutenberg
            database.set(isEnabled, forKey: Key.enabledOnce)
        }
        blog.editor.setMobileEditor(selectedEditor)
        ContextManager.sharedInstance().save(context)

        WPAnalytics.refreshMetadata()
    }

    private func shouldUpdateSettings(with newSetting: MobileEditor, for blog: Blog) -> Bool {
        return !wasGutenbergEnabledOnce(for: blog) || blog.editor.mobile != newSetting
    }

    private func trackSettingChange(to isEnabled: Bool) {
        let stat: WPAnalyticsStat = isEnabled ? .appSettingsGutenbergEnabled : .appSettingsGutenbergDisabled
        WPAppAnalytics.track(stat)
    }


    /// Synch the current editor settings with remote for the given site
    ///
    /// - Parameter blog: The site to synch editor settings
    func postSettingsToRemote(for blog: Blog) {
        let editorSettingsService = EditorSettingsService(managedObjectContext: context)
        editorSettingsService.postEditorSetting(for: blog, success: {}) { (error) in
            DDLogError("Failed to post new post selection with Error: \(error)")
        }
    }

    /// True if gutenberg editor has been enabled at least once on the given blog
    func wasGutenbergEnabledOnce(for blog: Blog) -> Bool {
        return database.object(forKey: Key.enabledOnce) != nil
    }

    /// True if gutenberg should be autoenabled for the blog hosting the given post.
    func shouldAutoenableGutenberg(for post: AbstractPost) -> Bool {
        let blog = post.blog
        return post.containsGutenbergBlocks() && !wasGutenbergEnabledOnce(for: blog)
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
        let blog = post.blog

        if post.isContentEmpty() {
            return shouldUseGutenbergForNewPosts(on: blog)
        } else {
            // It's an existing post
            return post.containsGutenbergBlocks()
        }
    }

    private func shouldUseGutenbergForNewPosts(on blog: Blog) -> Bool {
        guard let userSelectedEditor = blog.editor.mobile else {
            return getDefaultEditor(for: blog) == .gutenberg
        }

        return userSelectedEditor == .gutenberg
    }

    func getDefaultEditor(for blog: Blog) -> MobileEditor {
        if blog.isAccessibleThroughWPCom(),
            let accountID = blog.account?.userID?.intValue,
            accountID > MIN_WPCOM_USER_ID_TO_DEFAULT_GB {

            return .gutenberg
        }
        return oldAppWideIsGutenbergEnabled ? .gutenberg : .aztec
    }
}

@objc(GutenbergSettings)
class GutenbergSettingsBridge: NSObject {
    @objc(setGutenbergEnabled:forBlog:)
    static func setGutenbergEnabled(_ isEnabled: Bool, for blog: Blog) {
        GutenbergSettings().setGutenbergEnabled(isEnabled, for: blog)
    }

    @objc(postSettingsToRemoteForBlog:)
    static func postSettingsToRemote(for blog: Blog) {
        GutenbergSettings().postSettingsToRemote(for: blog)
    }
}
