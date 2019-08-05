import Foundation

/// Takes care of storing and accessing Gutenberg settings.
///
class GutenbergSettings {
    // MARK: - Enabled Editors Keys
    enum Key {
        static let appWideEnabled = "kUserDefaultsGutenbergEditorEnabled"
        static func enabledOnce(for blog: Blog) -> String {
            let url = (blog.url ?? "") as String
            return "com.wordpress.gutenberg-autoenabled-" + url
        }
    }

    enum TracksSwitchSource: String {
        case viaSiteSettings = "via-site-settings"
        case onSiteCreation = "on-site-creation"
        case onBlockPostOpening = "on-block-post-opening"
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
    func setGutenbergEnabled(_ isEnabled: Bool, for blog: Blog, source: TracksSwitchSource? = nil) {
        guard shouldUpdateSettings(enabling: isEnabled, for: blog) else {
            return
        }

        softSetGutenbergEnabled(isEnabled, for: blog, source: source)

        if isEnabled {
            database.set(true, forKey: Key.enabledOnce(for: blog))
        }
    }

    /// Sets gutenberg enabled without registering the enabled action ("enabledOnce")
    /// Use this to set gutenberg and still show the auto-enabled dialog.
    ///
    /// - Parameter blog: The site to set the
    func softSetGutenbergEnabled(_ isEnabled: Bool, for blog: Blog, source: TracksSwitchSource?) {
        guard shouldUpdateSettings(enabling: isEnabled, for: blog) else {
            return
        }

        if let source = source, blog.isGutenbergEnabled != isEnabled {
            trackSettingChange(to: isEnabled, from: source)
        }

        blog.mobileEditor = isEnabled ? .gutenberg : .aztec
        ContextManager.sharedInstance().save(context)

        WPAnalytics.refreshMetadata()
    }

    private func shouldUpdateSettings(enabling isEnablingGutenberg: Bool, for blog: Blog) -> Bool {
        let selectedEditor: MobileEditor = isEnablingGutenberg ? .gutenberg : .aztec
        return blog.mobileEditor != selectedEditor
    }

    private func trackSettingChange(to isEnabled: Bool, from source: TracksSwitchSource) {
        let stat: WPAnalyticsStat = isEnabled ? .appSettingsGutenbergEnabled : .appSettingsGutenbergDisabled
        let props: [String: Any] = [
            "source": source.rawValue
        ]
        WPAppAnalytics.track(stat, withProperties: props)
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
        return database.object(forKey: Key.enabledOnce(for: blog)) != nil
    }

    /// True if gutenberg should be autoenabled for the blog hosting the given post.
    func shouldAutoenableGutenberg(for post: AbstractPost) -> Bool {
        return !wasGutenbergEnabledOnce(for: post.blog)
    }

    func willShowDialog(for blog: Blog) {
        database.set(true, forKey: Key.enabledOnce(for: blog))
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
            return blog.isGutenbergEnabled
        } else {
            // It's an existing post
            return post.containsGutenbergBlocks()
        }
    }

    func getDefaultEditor(for blog: Blog) -> MobileEditor {
        return .aztec
    }
}

@objc(GutenbergSettings)
class GutenbergSettingsBridge: NSObject {
    @objc(setGutenbergEnabled:forBlog:)
    static func setGutenbergEnabled(_ isEnabled: Bool, for blog: Blog) {
        GutenbergSettings().setGutenbergEnabled(isEnabled, for: blog, source: .viaSiteSettings)
    }

    @objc(postSettingsToRemoteForBlog:)
    static func postSettingsToRemote(for blog: Blog) {
        GutenbergSettings().postSettingsToRemote(for: blog)
    }
}
