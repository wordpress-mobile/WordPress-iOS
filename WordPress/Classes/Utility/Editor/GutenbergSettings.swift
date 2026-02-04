import Foundation
import WordPressData
import WordPressShared

import WordPressCore

/// Takes care of storing and accessing Gutenberg settings.
///
class GutenbergSettings {
    // MARK: - Enabled Editors Keys
    enum Key {
        static let appWideEnabled = "kUserDefaultsGutenbergEditorEnabled"
        static func enabledOnce(forBlogURL url: String?) -> String {
            let url = urlString(fromBlogURL: url)
            return "com.wordpress.gutenberg-autoenabled-" + url
        }
        static func showPhase2Dialog(forBlogURL url: String?) -> String {
            let url = urlString(fromBlogURL: url)
            return "kShowGutenbergPhase2Dialog-" + url
        }
        static func themeStylesEnabled(forBlogURL url: String?) -> String {
            let url = urlString(fromBlogURL: url)
            return "com.wordpress.gutenberg-theme-styles-" + url
        }
        static let focalPointPickerTooltipShown = "kGutenbergFocalPointPickerTooltipShown"
        static let blockTypeImpressions = "kBlockTypeImpressions"

        private static func urlString(fromBlogURL url: String?) -> String {
            return (url ?? "")
            // New sites will add a slash at the end of URL.
            // This is removed when the URL is refreshed from remote.
            // Removing trailing '/' in case there is one for consistency.
            .removingTrailingCharacterIfExists("/")
        }
    }

    enum TracksSwitchSource: String {
        case viaSiteSettings = "via-site-settings"
        case onSiteCreation = "on-site-creation"
        case onBlockPostOpening = "on-block-post-opening"
        case onProgressiveRolloutPhase2 = "on-progressive-rollout-phase-2"
    }

    // MARK: - Internal variables
    private let database: KeyValueDatabase
    private var coreDataStack: CoreDataStackSwift {
        AppEnvironment.current.contextManager
    }

    // MARK: - Initialization
    init(database: KeyValueDatabase = UserDefaults.standard) {
        self.database = database
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
            database.set(true, forKey: Key.enabledOnce(forBlogURL: blog.url))
        }
    }

    func performGutenbergPhase2MigrationIfNeeded() {
        guard
            ReachabilityUtils.isInternetReachable(),
            let userID = coreDataStack.performQuery({ try? WPAccount.lookupDefaultWordPressComAccount(in: $0)?.userID })
        else {
            return
        }

        var rollout = GutenbergRollout(database: database)
        if rollout.shouldPerformPhase2Migration(userId: userID.intValue) {
            setGutenbergEnabledForAllSites()
            rollout.isUserInRolloutGroup = true
            trackSettingChange(to: true, from: .onProgressiveRolloutPhase2)
        }
    }

    private func setGutenbergEnabledForAllSites() {
        let blogURLs: [String?] = coreDataStack.performQuery { context in
            guard let blogs = try? BlogQuery().blogs(in: context) else { return [] }

            return blogs
                .filter { $0.editor == .aztec }
                .map { $0.url }
        }
        blogURLs.forEach { blogURL in
            setShowPhase2Dialog(true, forBlogURL: blogURL)
            database.set(true, forKey: Key.enabledOnce(forBlogURL: blogURL))
        }
        let editorSettingsService = EditorSettingsService(coreDataStack: coreDataStack)
        editorSettingsService.migrateGlobalSettingToRemote(isGutenbergEnabled: true, overrideRemote: true, onSuccess: {
            WPAnalytics.refreshMetadata()
        })
    }

    func shouldPresentInformativeDialog(for blog: Blog) -> Bool {
        return database.bool(forKey: Key.showPhase2Dialog(forBlogURL: blog.url))
    }

    func setShowPhase2Dialog(_ showDialog: Bool, forBlogURL url: String?) {
        database.set(showDialog, forKey: Key.showPhase2Dialog(forBlogURL: url))
    }

    /// Sets gutenberg enabled without registering the enabled action ("enabledOnce")
    /// Use this to set gutenberg and still show the auto-enabled dialog.
    ///
    /// - Parameter blog: The site to set the
    func softSetGutenbergEnabled(_ isEnabled: Bool, for blog: Blog, source: TracksSwitchSource?) {
        guard shouldUpdateSettings(enabling: isEnabled, for: blog) else {
            return
        }

        if let source, blog.isGutenbergEnabled != isEnabled {
            trackSettingChange(to: isEnabled, from: source)
        }

        let mobileEditor: MobileEditor = isEnabled ? .gutenberg : .aztec
        blog.mobileEditor = mobileEditor

        coreDataStack.performAndSave({ context in
            let blogInContext = try? context.existingObject(with: blog.objectID) as? Blog
            blogInContext?.mobileEditor = mobileEditor
        }, completion: {
            WPAnalytics.refreshMetadata()
        }, on: .main)
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
        let editorSettingsService = EditorSettingsService(coreDataStack: coreDataStack)
        editorSettingsService.postEditorSetting(for: blog, success: {}) { (error) in
            DDLogError("Failed to post new post selection with Error: \(error)")
        }
    }

    /// True if gutenberg editor has been enabled at least once on the given blog
    func wasGutenbergEnabledOnce(for blog: Blog) -> Bool {
        return database.object(forKey: Key.enabledOnce(forBlogURL: blog.url)) != nil
    }

    /// True if gutenberg should be autoenabled for the blog hosting the given post.
    func shouldAutoenableGutenberg(for post: AbstractPost) -> Bool {
        return !wasGutenbergEnabledOnce(for: post.blog)
    }

    func willShowDialog(for blog: Blog) {
        database.set(true, forKey: Key.enabledOnce(forBlogURL: blog.url))
    }

    /// True if it should show the tooltip for the focal point picker
    var focalPointPickerTooltipShown: Bool {
        get {
            database.bool(forKey: Key.focalPointPickerTooltipShown)
        }
        set {
            database.set(newValue, forKey: Key.focalPointPickerTooltipShown)
        }
    }

    var blockTypeImpressions: [String: Int] {
        get {
            database.object(forKey: Key.blockTypeImpressions) as? [String: Int] ?? [:]
        }
        set {
            database.set(newValue, forKey: Key.blockTypeImpressions)
        }
    }

    // MARK: - Gutenberg Choice Logic

    func isSimpleWPComSite(_ blog: Blog) -> Bool {
        return !blog.isAtomic() && blog.isHostedAtWPcom
    }

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
            return isSimpleWPComSite(post.blog) || blog.isGutenbergEnabled
        } else {
            // It's an existing post
            return post.containsGutenbergBlocks()
        }
    }

    func getDefaultEditor(for blog: Blog) -> MobileEditor {
        database.set(true, forKey: Key.enabledOnce(forBlogURL: blog.url))
        return .gutenberg
    }

    // MARK: - Theme Styles

    /// Returns whether theme styles should be enabled for the given blog.
    ///
    /// - Parameter blog: The blog to check theme styles setting for
    /// - Returns: true if theme styles are enabled (default: true), false if explicitly disabled
    func isThemeStylesEnabled(for blog: Blog) -> Bool {
        if !getSupports(.blockEditorSettings, for: blog) {
            return false
        }

        // Default to `true` if the user hasn't specifically set a preference
        guard database.hasEntry(forKey: Key.themeStylesEnabled(forBlogURL: blog.url)) else {
            return true
        }

        return database.bool(forKey: Key.themeStylesEnabled(forBlogURL: blog.url))
    }

    /// Sets whether theme styles should be enabled for the given blog.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether to enable theme styles
    ///   - blog: The blog to set theme styles setting for
    func setThemeStylesEnabled(_ isEnabled: Bool, for blog: Blog) {
        database.set(isEnabled, forKey: Key.themeStylesEnabled(forBlogURL: blog.url))
    }

    /// Sets whether the given API feature is available for the given blog. This is unrelated to whether it's *enabled* for that blog.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether to enable theme styles
    ///   - blog: The blog to set theme styles setting for
    @discardableResult
    func setSupports(_ feature: WordPressClient.Feature, _ newValue: Bool, for blog: Blog) -> Self {
        let key = "org.wordpress.gutenberg-supports-" + feature.stringValue + "-" + blog.locallyUniqueId
        database.set(newValue, forKey: key)
        return self
    }

    /// Returns whether the given API feature is available for the given blog. This is unrelated to whether it's *enabled* for that blog.
    ///
    /// - Parameter blog: The blog to check the given API feature for
    /// - Returns: true if the feature is available, false if the server hasn't been queried for support yet, or if the server doesn't support it.
    func getSupports(_ feature: WordPressClient.Feature, for blog: Blog) -> Bool {
        let key = "org.wordpress.gutenberg-supports-" + feature.stringValue + "-" + blog.locallyUniqueId

        if database.object(forKey: key) != nil {
            return database.bool(forKey: key)
        }

        return false
    }
}

@objc(GutenbergSettings)
public class GutenbergSettingsBridge: NSObject {
    @objc(setGutenbergEnabled:forBlog:)
    public static func setGutenbergEnabled(_ isEnabled: Bool, for blog: Blog) {
        GutenbergSettings().setGutenbergEnabled(isEnabled, for: blog, source: .viaSiteSettings)
    }

    @objc(postSettingsToRemoteForBlog:)
    public static func postSettingsToRemote(for blog: Blog) {
        GutenbergSettings().postSettingsToRemote(for: blog)
    }

    @objc(isSimpleWPComSite:)
    public static func isSimpleWPComSite(_ blog: Blog) -> Bool {
        return GutenbergSettings().isSimpleWPComSite(blog)
    }

    @objc(isThemeStylesEnabledForBlog:)
    public static func isThemeStylesEnabled(for blog: Blog) -> Bool {
        return GutenbergSettings().isThemeStylesEnabled(for: blog)
    }

    @objc(setThemeStylesEnabled:forBlog:)
    public static func setThemeStylesEnabled(_ isEnabled: Bool, for blog: Blog) {
        GutenbergSettings().setThemeStylesEnabled(isEnabled, for: blog)
    }

    @objc(isThemeStylesSupportedForBlog:)
    public static func canEnableThemeStyleSetting(for blog: Blog) -> Bool {
        let settings = GutenbergSettings()

        // It's possible for a theme to publish editor styles while not being a block theme.
        // We'll leave it up to the user to decide if they want to use styles or not, and will enable them by default.
        return settings.getSupports(.blockEditorSettings, for: blog)
    }

    @objc(siteIsUsingBlockTheme:)
    public static func siteIsUsingBlockTheme(for blog: Blog) -> Bool {
        let settings = GutenbergSettings()

        return settings.getSupports(.blockTheme, for: blog)
    }
}

private extension String {
    func removingTrailingCharacterIfExists(_ character: Character) -> String {
        if self.last == character {
            return String(dropLast())
        }
        return self
    }
}
