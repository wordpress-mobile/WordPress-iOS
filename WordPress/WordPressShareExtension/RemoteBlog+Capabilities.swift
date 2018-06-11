import Foundation
import WordPressKit

extension RemoteBlog {
    /// Enumeration that contains all of the RemoteBlog's available capabilities.
    ///
    public enum Capability: String {
        case deleteOthersPosts  = "delete_others_posts"
        case deletePosts        = "delete_posts"
        case editOthersPages    = "edit_others_pages"
        case editOthersPosts    = "edit_others_posts"
        case editPages          = "edit_pages"
        case editPosts          = "edit_posts"
        case editThemeOptions   = "edit_theme_options"
        case editUsers          = "edit_users"
        case listUsers          = "list_users"
        case manageCategories   = "manage_categories"
        case manageOptions      = "manage_options"
        case promoteUsers       = "promote_users"
        case publishPosts       = "publish_posts"
        case uploadFiles        = "upload_files"
        case viewStats          = "view_stats"
    }


    /// Returns true if a given capability is enabled. False otherwise
    ///
    public func isUserCapableOf(_ capability: Capability) -> Bool {
        return capabilities?[capability.rawValue] as? Bool ?? false
    }

    /// Returns true if the current user is allowed to list a Blog's Users
    ///
    @objc public func isListingUsersAllowed() -> Bool {
        return isUserCapableOf(.listUsers)
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
}
