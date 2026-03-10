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

    /// Returns true if the current user is allowed to see Jetpack's Backups
    ///
    @objc public func isBackupsAllowed() -> Bool {
        return isUserCapableOf("backup") || isUserCapableOf("backup-daily") || isUserCapableOf("backup-realtime")
    }

    /// Returns true if the current user is allowed to see Jetpack's Scan
    ///
    @objc public func isScanAllowed() -> Bool {
        return !hasBusinessPlan && isUserCapableOf("scan")
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
