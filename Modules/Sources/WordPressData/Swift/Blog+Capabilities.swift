import Foundation

/// This Extension encapsulates all of the Blog-Capabilities related helpers.
///
extension Blog {
    /// Enumeration that contains all of the Blog's available capabilities.
    ///
    public enum Capability: String {
        case activateWordAds = "activate_wordads"
        case deleteOthersPosts = "delete_others_posts"
        case deletePosts = "delete_posts"
        case editOthersPages = "edit_others_pages"
        case editOthersPosts = "edit_others_posts"
        case editPages = "edit_pages"
        case editPosts = "edit_posts"
        case editThemeOptions = "edit_theme_options"
        case editUsers = "edit_users"
        case listUsers = "list_users"
        case manageCategories = "manage_categories"
        case manageOptions = "manage_options"
        case promoteUsers = "promote_users"
        case publishPosts = "publish_posts"
        case uploadFiles = "upload_files"
        case viewStats = "view_stats"
    }

    /// Features included in the site's current plan and products, as reported
    /// by the sites API (`plan.features.active`). The slugs mirror wpcom's
    /// WPCOM_Features and are what the web client checks before showing
    /// feature UI, so they are the source of truth for plan gating.
    ///
    public enum PlanFeature: String {
        case backupsSelfServe = "backups-self-serve"
        case scanSelfServe = "scan-self-serve"
    }

    /// Returns true if a given feature is included in the site's plan. False otherwise
    ///
    public func hasPlanFeature(_ feature: PlanFeature) -> Bool {
        return planActiveFeatures?.contains(feature.rawValue) ?? false
    }

    /// Returns true if a given capability is enabled. False otherwise
    ///
    public func isUserCapableOf(_ capability: Capability) -> Bool {
        return isUserCapableOf(capability.rawValue)
    }

    /// Returns true if the current user is allowed to publish to the Blog
    ///
    @objc public func isPublishingPostsAllowed() -> Bool {
        return isUserCapableOf(.publishPosts)
    }

    /// Returns true if the current user is allowed to upload files to the Blog
    ///
    @objc public func isUploadingFilesAllowed() -> Bool {
        return isUserCapableOf(.uploadFiles)
    }

    /// Returns true if the current user is allowed to see Jetpack's Backups.
    ///
    /// The backup capability alone is not enough: WordPress.com grants it to
    /// Personal and Premium Simple sites because it backs them up internally,
    /// but those backups have no user-facing UI. The backups-self-serve plan
    /// feature is what gates the Backup UI on the web.
    @objc public func isBackupsAllowed() -> Bool {
        return hasPlanFeature(.backupsSelfServe)
            && (isUserCapableOf("backup") || isUserCapableOf("backup-daily") || isUserCapableOf("backup-realtime"))
    }

    /// Returns true if the current user is allowed to see Jetpack's Scan.
    ///
    /// Like backups, the scan capability is granted to Personal and Premium
    /// Simple sites whose scans are managed internally with no user-facing UI.
    /// The scan-self-serve plan feature is what gates the Scan UI on the web.
    @objc public func isScanAllowed() -> Bool {
        return !hasBusinessPlan && hasPlanFeature(.scanSelfServe) && isUserCapableOf("scan")
    }

    /// Returns true if the current user is allowed to view Stats
    ///
    public var isViewingStatsAllowed: Bool {
        isAdmin || isUserCapableOf(.viewStats)
    }

    /// Returns true if WordAds is actually active on the site
    ///
    @objc public func isWordAdsActive() -> Bool {
        return getOption(name: "wordads") ?? false
    }

    private func isUserCapableOf(_ capability: String) -> Bool {
        return capabilities?[capability] as? Bool ?? false
    }

    public var userCanUploadMedia: Bool {
        // Self-hosted non-Jetpack blogs have no capabilities, so we'll just assume that users can post media
        capabilities != nil ? isUploadingFilesAllowed() : true
    }
}
