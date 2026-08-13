import Foundation
import WordPressCore
import WordPressData
import WordPressShared

/// The resolved state of the third-party blocks ("plugins") capability for a site.
///
/// Mirrors Android's `EditorCapabilityResolver` so both platforms surface the feature
/// identically. The remote feature flag, the site's advertised capability, and the user's
/// per-site preference compose as AND: the editor loads third-party blocks only when all
/// three agree.
enum ThirdPartyBlocksCapability: Equatable {
    /// The feature is not being offered. The Site Settings row is hidden.
    case hidden

    /// The site cannot support third-party blocks. The row is shown but disabled, with an
    /// explanation, matching Android's treatment.
    case unsupported

    /// The site supports third-party blocks. The associated value is the user's preference.
    case available(Bool)

    /// Whether the editor should load third-party blocks.
    ///
    /// True only for `.available(true)` — the collapsed form of the precedence table.
    var shouldApplyInEditor: Bool {
        switch self {
        case .hidden, .unsupported:
            return false
        case .available(let isEnabled):
            return isEnabled
        }
    }

    /// Whether the Site Settings row should be shown at all.
    var isVisibleInSiteSettings: Bool {
        switch self {
        case .hidden:
            return false
        case .unsupported, .available:
            return true
        }
    }

    /// Whether the Site Settings row should be interactive.
    var isInteractive: Bool {
        switch self {
        case .hidden, .unsupported:
            return false
        case .available:
            return true
        }
    }
}

extension GutenbergSettings {
    /// Resolves whether third-party blocks are offered, supported, and enabled for the given blog.
    ///
    /// Precedence:
    /// 1. Remote flag off → `.hidden`
    /// 2. Site can't authenticate non-core block requests → `.unsupported`
    /// 3. Site doesn't advertise the `editor-assets` route → `.unsupported`
    /// 4. Otherwise → `.available(userPreference)`
    ///
    /// A site whose capability has not been probed yet is treated as supported rather than
    /// unsupported. The probe is fire-and-forget (see `EditorDependencyManager`), so it may not
    /// have completed — or, on a fresh install, run at all — by the time this is called. Assuming
    /// support keeps the setting reachable; the editor still degrades gracefully if the route is
    /// genuinely absent, whereas assuming the opposite would disable the row on capable sites.
    ///
    /// - Parameters:
    ///   - blog: The blog to resolve the capability for
    ///   - appPassword: The blog's application password, if one has already been loaded. Pass this
    ///     to avoid a redundant keychain read; omit it to have the value looked up.
    ///   - isFeatureFlagEnabled: Whether the remote feature flag is on. Defaults to the live value.
    /// - Returns: The resolved capability
    func resolveThirdPartyBlocks(
        for blog: Blog,
        appPassword: String? = nil,
        keychain: KeychainAccessible = AppKeychain(),
        isFeatureFlagEnabled: Bool = RemoteFeatureFlag.newGutenbergPlugins.enabled()
    ) -> ThirdPartyBlocksCapability {
        guard isFeatureFlagEnabled else {
            return .hidden
        }

        // Requires a WP.com Simple site, or an application password to authenticate all REST API
        // requests — including those originating from non-core blocks.
        //
        // The keychain lookup is a synchronous Security-framework call and this runs on the main
        // thread while cells and footers are built, so it is deferred behind the WP.com check
        // rather than resolved up front.
        let hasApplicationPassword = {
            (appPassword ?? (try? blog.getApplicationToken(using: keychain))) != nil
        }
        guard blog.isHostedAtWPcom || hasApplicationPassword() else {
            return .unsupported
        }

        // Treat "not probed yet" as supported — see the note above.
        let hasProbed = hasProbedSupport(for: .editorAssets, blog: blog)
        guard !hasProbed || getSupports(.editorAssets, for: blog) else {
            return .unsupported
        }

        return .available(isThirdPartyBlocksEnabled(for: blog))
    }
}

extension GutenbergSettingsBridge {
    @objc(isThirdPartyBlocksEnabledForBlog:)
    public static func isThirdPartyBlocksEnabled(for blog: Blog) -> Bool {
        GutenbergSettings().isThirdPartyBlocksEnabled(for: blog)
    }

    @objc(setThirdPartyBlocksEnabled:forBlog:)
    public static func setThirdPartyBlocksEnabled(_ isEnabled: Bool, for blog: Blog) {
        GutenbergSettings().setThirdPartyBlocksEnabled(isEnabled, for: blog)
        invalidatePrefetchedEditor(for: blog)
    }

    /// Discards the editor dependencies prefetched for this site.
    ///
    /// The editor is warmed up ahead of time using an `EditorConfiguration` built from these
    /// preferences, so a cached editor would keep the setting the user just changed until the
    /// cache happened to be evicted.
    static func invalidatePrefetchedEditor(for blog: Blog) {
        let blogID = TaggedManagedObjectID(blog)
        Task {
            await EditorDependencyManager.shared.invalidate(for: blogID)
        }
    }

    /// The resolved third-party blocks capability, in a form Objective-C can hold onto.
    ///
    /// Resolving reads the keychain, so callers that ask more than once per pass — Site Settings
    /// builds its sections, cell, and footer from it — should resolve once and pass the result to
    /// the `...ForCapability:` accessors below.
    @objc(ThirdPartyBlocksCapabilityValue)
    public enum CapabilityValue: Int {
        case hidden
        case unsupported
        case available
    }

    @objc(thirdPartyBlocksCapabilityForBlog:)
    public static func thirdPartyBlocksCapability(for blog: Blog) -> CapabilityValue {
        switch GutenbergSettings().resolveThirdPartyBlocks(for: blog) {
        case .hidden: return .hidden
        case .unsupported: return .unsupported
        case .available: return .available
        }
    }

    /// Whether the Site Settings row should be shown.
    @objc(isThirdPartyBlocksVisibleForCapability:)
    public static func isThirdPartyBlocksVisible(for capability: CapabilityValue) -> Bool {
        capability != .hidden
    }

    /// Whether the Site Settings row should be interactive. A visible but non-interactive row
    /// means the site can't support the feature.
    @objc(isThirdPartyBlocksSupportedForCapability:)
    public static func isThirdPartyBlocksSupported(for capability: CapabilityValue) -> Bool {
        capability == .available
    }
}
