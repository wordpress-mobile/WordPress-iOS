import Foundation


/// This Extension encapsulates all of the Blog-Capabilities related helpers.
///
extension Blog {
    /// Enumeration that contains all of the Blog's available capabilities.
    ///
    public enum Capability: String {
        case DeleteOthersPosts  = "delete_others_posts"
        case DeletePosts        = "delete_posts"
        case EditOthersPages    = "edit_others_pages"
        case EditOthersPosts    = "edit_others_posts"
        case EditPages          = "edit_pages"
        case EditPosts          = "edit_posts"
        case EditThemeOptions   = "edit_theme_options"
        case EditUsers          = "edit_users"
        case ListUsers          = "list_users"
        case ManageCategories   = "manage_categories"
        case ManageOptions      = "manage_options"
        case PromoteUsers       = "promote_users"
        case PublishPosts       = "publish_posts"
        case UploadFiles        = "upload_files"
        case ViewStats          = "view_stats"
    }


    /// Returns true if a given capability is enabled. False otherwise
    ///
    public func isUserCapableOf(_ capability: Capability) -> Bool {
        return capabilities?[capability.rawValue] as? Bool ?? false
    }

    /// Returns true if the current user is allowed to list a Blog's Users
    ///
    public func isListingUsersAllowed() -> Bool {
        return isUserCapableOf(.ListUsers)
    }

    /// Returns true if the current user is allowed to publish to the Blog
    ///
    public func isPublishingPostsAllowed() -> Bool {
        return isUserCapableOf(.PublishPosts)
    }

    /// Returns true if the current user is allowed to upload files to the Blog
    ///
    public func isUploadingFilesAllowed() -> Bool {
        return isUserCapableOf(.UploadFiles)
    }
}
