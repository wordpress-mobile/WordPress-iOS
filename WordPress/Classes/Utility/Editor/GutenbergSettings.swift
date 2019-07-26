import Foundation

/// Takes care of storing and accessing Gutenberg settings.
///
class GutenbergSettings {
    // MARK: - Enabled Editors Keys
    enum Key {
        static let appWideEnabled = "kUserDefaultsGutenbergEditorEnabled"
        static func enabledOnce(for blog: Blog) -> String {
            let url = (blog.displayURL ?? "") as String
            return "com.wordpress.gutenberg-autoenabled-" + url
        }
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
            database.set(true, forKey: Key.enabledOnce(for: blog))
        }

        blog.mobileEditor = selectedEditor
        ContextManager.sharedInstance().save(context)

        WPAnalytics.refreshMetadata()
    }

    private func shouldUpdateSettings(with newSetting: MobileEditor, for blog: Blog) -> Bool {
        return blog.mobileEditor != newSetting
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
        // If gutenberg was "globaly" enabled before, will take precedence over the new per-site flag
        return database.object(forKey: Key.appWideEnabled) != nil || database.object(forKey: Key.enabledOnce(for: blog)) != nil
    }

    /// True if gutenberg should be autoenabled for the blog hosting the given post.
    func shouldAutoenableGutenberg(for post: AbstractPost) -> Bool {
        return !wasGutenbergEnabledOnce(for: post.blog)
    }

    func didAutoenableGutenberg() {
        database.set(true, forKey: Key.appWideEnabled)
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
        guard let userSelectedEditor = blog.mobileEditor else {
            return getDefaultEditor(for: blog) == .gutenberg
        }

        return userSelectedEditor == .gutenberg
    }

    func getDefaultEditor(for blog: Blog) -> MobileEditor {
        // Default to gutenberg on WPCom/Jetpack sites
        return blog.isAccessibleThroughWPCom() ? .gutenberg : .aztec
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
