import Foundation
import WordPressData
import WordPressKitModels

/// The fields of one settings save. Callers declare exactly what they
/// changed; nil fields are not sent and not persisted. This exists because
/// deriving the delta from Core Data dirty state is unreliable across
/// in-flight saves (see the design doc's "Why not infer the delta" section).
@objc public final class BlogSettingsChanges: NSObject {
    // General
    @objc public var name: String?
    @objc public var tagline: String?
    @objc public var privacy: NSNumber?
    @objc public var languageID: NSNumber?
    @objc public var gmtOffset: NSNumber?
    @objc public var timezoneString: String?
    // Writing
    @objc public var defaultCategoryID: NSNumber?
    @objc public var defaultPostFormat: String?
    @objc public var dateFormat: String?
    @objc public var timeFormat: String?
    @objc public var startOfWeek: String?
    @objc public var postsPerPage: NSNumber?
    // Discussion (Bool-valued entries are NSNumber-wrapped Bools)
    @objc public var commentsAllowed: NSNumber?
    @objc public var commentsBlocklistKeys: String?
    @objc public var commentsCloseAutomatically: NSNumber?
    @objc public var commentsCloseAutomaticallyAfterDays: NSNumber?
    @objc public var commentsFromKnownUsersAllowlisted: NSNumber?
    @objc public var commentsMaximumLinks: NSNumber?
    @objc public var commentsModerationKeys: String?
    @objc public var commentsPagingEnabled: NSNumber?
    @objc public var commentsPageSize: NSNumber?
    @objc public var commentsRequireManualModeration: NSNumber?
    @objc public var commentsRequireNameAndEmail: NSNumber?
    @objc public var commentsRequireRegistration: NSNumber?
    @objc public var commentsSortOrderAscending: NSNumber?
    @objc public var commentsThreadingDepth: NSNumber?
    @objc public var commentsThreadingEnabled: NSNumber?
    @objc public var pingbackInboundEnabled: NSNumber?
    @objc public var pingbackOutboundEnabled: NSNumber?
    // Related posts
    @objc public var relatedPostsEnabled: NSNumber?
    @objc public var relatedPostsShowHeadline: NSNumber?
    @objc public var relatedPostsShowThumbnails: NSNumber?
    // Traffic
    @objc public var ampEnabled: NSNumber?
    // Sharing
    @objc public var sharingButtonStyle: String?
    @objc public var sharingLabel: String?
    @objc public var sharingTwitterName: String?
    @objc public var sharingCommentLikesEnabled: NSNumber?
    @objc public var sharingDisabledLikes: NSNumber?
    @objc public var sharingDisabledReblogs: NSNumber?
    // Site icon (0 = remove, mirroring the icon UI's convention)
    @objc public var iconMediaID: NSNumber?

    private var allValues: [Any?] {
        [
            name, tagline, privacy, languageID, gmtOffset, timezoneString,
            defaultCategoryID, defaultPostFormat, dateFormat, timeFormat,
            startOfWeek, postsPerPage,
            commentsAllowed, commentsBlocklistKeys, commentsCloseAutomatically,
            commentsCloseAutomaticallyAfterDays, commentsFromKnownUsersAllowlisted,
            commentsMaximumLinks, commentsModerationKeys, commentsPagingEnabled,
            commentsPageSize, commentsRequireManualModeration,
            commentsRequireNameAndEmail, commentsRequireRegistration,
            commentsSortOrderAscending, commentsThreadingDepth,
            commentsThreadingEnabled, pingbackInboundEnabled, pingbackOutboundEnabled,
            relatedPostsEnabled, relatedPostsShowHeadline, relatedPostsShowThumbnails,
            ampEnabled,
            sharingButtonStyle, sharingLabel, sharingTwitterName,
            sharingCommentLikesEnabled, sharingDisabledLikes, sharingDisabledReblogs,
            iconMediaID
        ]
    }

    @objc public var isEmpty: Bool {
        allValues.allSatisfy { $0 == nil }
    }

    func toRemoteBlogSettings() -> RemoteBlogSettings {
        let remote = RemoteBlogSettings()
        remote.name = name
        remote.tagline = tagline
        remote.privacy = privacy
        remote.languageID = languageID
        remote.gmtOffset = gmtOffset
        remote.timezoneString = timezoneString
        remote.defaultCategoryID = defaultCategoryID
        remote.defaultPostFormat = defaultPostFormat
        remote.dateFormat = dateFormat
        remote.timeFormat = timeFormat
        remote.startOfWeek = startOfWeek
        remote.postsPerPage = postsPerPage
        remote.commentsAllowed = commentsAllowed
        remote.commentsBlocklistKeys = commentsBlocklistKeys
        remote.commentsCloseAutomatically = commentsCloseAutomatically
        remote.commentsCloseAutomaticallyAfterDays = commentsCloseAutomaticallyAfterDays
        remote.commentsFromKnownUsersAllowlisted = commentsFromKnownUsersAllowlisted
        remote.commentsMaximumLinks = commentsMaximumLinks
        remote.commentsModerationKeys = commentsModerationKeys
        remote.commentsPagingEnabled = commentsPagingEnabled
        remote.commentsPageSize = commentsPageSize
        remote.commentsRequireManualModeration = commentsRequireManualModeration
        remote.commentsRequireNameAndEmail = commentsRequireNameAndEmail
        remote.commentsRequireRegistration = commentsRequireRegistration
        if let commentsSortOrderAscending {
            remote.commentsSortOrderAscending = commentsSortOrderAscending.boolValue
        }
        remote.commentsThreadingDepth = commentsThreadingDepth
        remote.commentsThreadingEnabled = commentsThreadingEnabled
        remote.pingbackInboundEnabled = pingbackInboundEnabled
        remote.pingbackOutboundEnabled = pingbackOutboundEnabled
        remote.relatedPostsEnabled = relatedPostsEnabled
        remote.relatedPostsShowHeadline = relatedPostsShowHeadline
        remote.relatedPostsShowThumbnails = relatedPostsShowThumbnails
        remote.ampEnabled = ampEnabled
        remote.sharingButtonStyle = sharingButtonStyle
        remote.sharingLabel = sharingLabel
        remote.sharingTwitterName = sharingTwitterName
        remote.sharingCommentLikesEnabled = sharingCommentLikesEnabled
        remote.sharingDisabledLikes = sharingDisabledLikes
        remote.sharingDisabledReblogs = sharingDisabledReblogs
        remote.iconMediaID = iconMediaID
        return remote
    }

    /// Applies only the declared fields, mirroring the transforms in
    /// `-[BlogService updateSettings:withRemoteSettings:]` (the read-path
    /// merge, which must never be used for sparse writes because it
    /// assigns every field unconditionally).
    func apply(to settings: BlogSettings) {
        if let name { settings.name = name }
        if let tagline { settings.tagline = tagline }
        if let privacy { settings.privacy = privacy }
        if let languageID { settings.languageID = languageID }
        if let gmtOffset { settings.gmtOffset = gmtOffset }
        if let timezoneString { settings.timezoneString = timezoneString }
        if let defaultCategoryID { settings.defaultCategoryID = defaultCategoryID }
        if let defaultPostFormat { settings.defaultPostFormat = defaultPostFormat }
        if let dateFormat { settings.dateFormat = dateFormat }
        if let timeFormat { settings.timeFormat = timeFormat }
        if let startOfWeek { settings.startOfWeek = startOfWeek }
        if let postsPerPage { settings.postsPerPage = postsPerPage }
        if let commentsAllowed { settings.commentsAllowed = commentsAllowed }
        if let commentsBlocklistKeys {
            settings.commentsBlocklistKeys = Set(
                commentsBlocklistKeys
                    .components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
            )
        }
        if let commentsCloseAutomatically {
            settings.commentsCloseAutomatically = commentsCloseAutomatically.boolValue
        }
        if let commentsCloseAutomaticallyAfterDays {
            settings.commentsCloseAutomaticallyAfterDays = commentsCloseAutomaticallyAfterDays
        }
        if let commentsFromKnownUsersAllowlisted {
            settings.commentsFromKnownUsersAllowlisted = commentsFromKnownUsersAllowlisted.boolValue
        }
        if let commentsMaximumLinks { settings.commentsMaximumLinks = commentsMaximumLinks }
        if let commentsModerationKeys {
            settings.commentsModerationKeys = Set(
                commentsModerationKeys
                    .components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
            )
        }
        if let commentsPagingEnabled {
            settings.commentsPagingEnabled = commentsPagingEnabled.boolValue
        }
        if let commentsPageSize { settings.commentsPageSize = commentsPageSize }
        if let commentsRequireManualModeration {
            settings.commentsRequireManualModeration = commentsRequireManualModeration.boolValue
        }
        if let commentsRequireNameAndEmail {
            settings.commentsRequireNameAndEmail = commentsRequireNameAndEmail.boolValue
        }
        if let commentsRequireRegistration {
            settings.commentsRequireRegistration = commentsRequireRegistration.boolValue
        }
        if let commentsSortOrderAscending {
            settings.commentsSortOrderAscending = commentsSortOrderAscending.boolValue
        }
        if let commentsThreadingDepth { settings.commentsThreadingDepth = commentsThreadingDepth }
        if let commentsThreadingEnabled {
            settings.commentsThreadingEnabled = commentsThreadingEnabled.boolValue
        }
        if let pingbackInboundEnabled { settings.pingbackInboundEnabled = pingbackInboundEnabled }
        if let pingbackOutboundEnabled {
            settings.pingbackOutboundEnabled = pingbackOutboundEnabled.boolValue
        }
        if let relatedPostsEnabled { settings.relatedPostsEnabled = relatedPostsEnabled.boolValue }
        if let relatedPostsShowHeadline {
            settings.relatedPostsShowHeadline = relatedPostsShowHeadline.boolValue
        }
        if let relatedPostsShowThumbnails {
            settings.relatedPostsShowThumbnails = relatedPostsShowThumbnails.boolValue
        }
        if let ampEnabled { settings.ampEnabled = ampEnabled.boolValue }
        if let sharingButtonStyle { settings.sharingButtonStyle = sharingButtonStyle }
        if let sharingLabel { settings.sharingLabel = sharingLabel }
        if let sharingTwitterName { settings.sharingTwitterName = sharingTwitterName }
        if let sharingCommentLikesEnabled {
            settings.sharingCommentLikesEnabled = sharingCommentLikesEnabled.boolValue
        }
        if let sharingDisabledLikes {
            settings.sharingDisabledLikes = sharingDisabledLikes.boolValue
        }
        if let sharingDisabledReblogs {
            settings.sharingDisabledReblogs = sharingDisabledReblogs.boolValue
        }
        if let iconMediaID { settings.iconMediaID = iconMediaID }
    }
}
