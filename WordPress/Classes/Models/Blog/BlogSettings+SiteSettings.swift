import WordPressAPI
import WordPressData

extension BlogSettings {
    /// Applies site settings fetched from the WordPress REST API (via the Rust
    /// networking layer) to this Core Data model.
    ///
    /// Only fields that are present in the REST API response are updated.
    /// Fields that the Core REST API does not provide (e.g. sharing, related
    /// posts, AMP) are left unchanged.
    ///
    /// Must be called on the managed object context's queue.
    func apply(_ siteSettings: SiteSettingsWithEditContext) {
        // General
        name = siteSettings.title
        tagline = siteSettings.description
        timezoneString = siteSettings.timezone

        // Writing
        let format = siteSettings.defaultPostFormat
        defaultPostFormat = (format.isEmpty || format == "0") ? "standard" : format
        defaultCategoryID = NSNumber(value: siteSettings.defaultCategory)
        dateFormat = siteSettings.dateFormat
        timeFormat = siteSettings.timeFormat
        startOfWeek = String(siteSettings.startOfWeek)
        postsPerPage = NSNumber(value: siteSettings.postsPerPage)

        // Discussion
        if let commentStatus = siteSettings.defaultCommentStatus {
            commentsAllowed = commentStatus == .open
        }
        if let pingStatus = siteSettings.defaultPingStatus {
            pingbackInboundEnabled = pingStatus == .open
        }
    }
}
