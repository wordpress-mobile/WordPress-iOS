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

    let context = Environment.current.contextManager.mainContext

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
    }

    convenience init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }

    // MARK: Public accessors

//    func isGutenbergEnabled(for blog: Blog) -> Bool {
//        return blog.editor.mobile == .gutenberg
//    }

    func setGutenbergEnabled(_ isEnabled: Bool, for blog: Blog) {
        let selectedEditor: MobileEditor = isEnabled ? .gutenberg : .aztec
        guard shouldUpdateSettings(with: selectedEditor, for: blog) else {
            return
        }

        if blog.isGutenbergEnabled != isEnabled {
            trackSettingChange(to: isEnabled)
        }

        blog.editor.setMobileEditor(selectedEditor)
        ContextManager.sharedInstance().save(context)

        WPAnalytics.refreshMetadata()
    }

    func postSettingsToRemote(for blog: Blog) {
        let editorSettingsService = EditorSettingsService(managedObjectContext: context)
        editorSettingsService.postEditorSetting(for: blog, success: {}) { (error) in
            DDLogError("Failed to post new post selection with Error: \(error)")
        }
    }

    private func shouldUpdateSettings(with newSetting: MobileEditor, for blog: Blog) -> Bool {
        return !wasGutenbergEnabledOnce(for: blog) || blog.editor.mobile != newSetting
    }

    /// True if gutenberg editor has been enabled at least once
    func wasGutenbergEnabledOnce(for blog: Blog) -> Bool {
        return blog.editor.mobile != nil
    }

    private func trackSettingChange(to isEnabled: Bool) {
        let stat: WPAnalyticsStat = isEnabled ? .appSettingsGutenbergEnabled : .appSettingsGutenbergDisabled
        WPAppAnalytics.track(stat)
    }

    func shouldAutoenableGutenberg(for post: AbstractPost) -> Bool {
        return  post.containsGutenbergBlocks() && !wasGutenbergEnabledOnce(for: post.blog) && post.blog.editor.web == .gutenberg
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
            return blog.editor.mobile == .gutenberg && blog.editor.web == .gutenberg
        } else {
            // It's an existing post
            return post.containsGutenbergBlocks()
        }
    }
}
