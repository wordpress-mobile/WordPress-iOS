import Foundation
import CoreData

extension Blog {
    /// Unusued, to be removed.
    @available(*, unavailable)
    @NSManaged var apiKey: String?

    /// Deprecated, it used to store the blog ID, but it's useless on self hosted, so we're moving to dotComID instead for clarity.
    @available(*, unavailable, message="Use dotComID instead")
    @NSManaged var blogID: NSNumber

    /// The ID for the blog's current theme. Only present for WordPress.com blogs if themes have been Cached.
    @NSManaged var currentThemeId: String?

    /// Unused, to be removed.
    @available(*, unavailable)
    @NSManaged var hasOlderPages: Bool

    /// Unused, to be removed.
    @available(*, unavailable)
    @NSManaged var hasOlderPosts: Bool

    /// URL for the site icon.
    @NSManaged var icon: String?

    /// Unused, to ne removed.
    @available(*, unavailable)
    @NSManaged var isActivated: Bool

    /// Stores if the current user is an administrator of the blog.
    /// - warning: This is not 100% reliable: if the API is unable to tell us if the user is an admin, we check if the user can edit the blog title and use that as an indicator.
    @NSManaged var isAdmin: Bool

    /// Stores if the blog is hosted on WordPress.com.
    @NSManaged var isHostedAtWPcom: Bool

    /// Stores if the blog has more than one author.
    @NSManaged var isMultiAuthor: Bool

    /// Date of the last time comments were synced.
    @NSManaged var lastCommentsSync: NSDate

    /// Date of the last time pages were synced.
    @NSManaged var lastPagesSync: NSDate

    /// Date of the last time posts were synced.
    @NSManaged var lastPostsSync: NSDate

    /// Unusued, to be removed.
    @available(*, unavailable)
    @NSManaged var lastStatsSync: NSDate

    /// WordPress version for which we last alerted the user about a required update.
    /// When the Blog's version is lower than the required MinimumVersion, we show an alert to the user. The MinimumVersion value at that time is stored here so we only show the alert once.
    @NSManaged var lastUpdateWarning: String?

    /// Stores the blog options as they come from the API.
    ///
    /// For legacy reasons, this currently tries to mimic the structure of the dictionary returned by XML-RPC's wp.getOptions.
    ///
    /// Each value in the dictionary should be a dictionary with keys: "value", "desc", and "readonly".
    ///
    /// For convenience, use getOptionValue(_) to get the value for a specific option.
    ///
    /// - seealso: getOptionValue(_)
    @NSManaged var options: [String: AnyObject]?

    /// Stores the product ID of the blog's plan.
    @NSManaged var planID: NSNumber?

    /// Post formats supported by the blog.
    /// The key is the post format "slug", and the value is the "label".
    @NSManaged var postFormats: [String: String]?

    /// Full URL to the site.
    @NSManaged var url: String

    /// Stores the username for self hosted blogs.
    /// - warning: for WordPress.com or Jetpack managed sites this will be `nil`. Use `usernameForSite` instead
    /// - seealso: usernameForSite
    @NSManaged var username: String?

    /// Stores if the blog should be visible.
    /// WordPress.com supports hiding blogs from the blog list by going to the [My Blogs](https://dashboard.wordpress.com/wp-admin/index.php?page=my-blogs) section. This property defaults to `true` so self hosted blogs are always visible.
    @NSManaged var visible: Bool

    /// URL for the XML-RPC endpoing
    @NSManaged var xmlrpc: String


    // MARK: - Relationships

    /// The associated WordPress.com account, if it's the default account
    /// If this is a self hosted site with Jetpack connected to a WordPress.com account different than the default account, this will be `nil` and the connected WordPress.com account will be set in `jetpackAccount`.
    @NSManaged var account: WPAccount?

    /// Inverse relationship to `WPAccount.defaultBlog`. Not very useful, but Core Data requires it, so added it here for completeness.
    @NSManaged var accountForDefaultBlog: WPAccount?

    /// Cached categories for this blog.
    @NSManaged var categories: Set<PostCategory>

    /// Cached comments for this blog.
    @NSManaged var comments: Set<Comment>

    /// Cached Publicize connections for this blog.
    @NSManaged var connections: Set<PublicizeConnection>

    /// The connected WordPress.com account for a Jetpack site, if different from the default WordPress.com account.
    @NSManaged var jetpackAccount: WPAccount?

    /// Cached media items for this blog.
    @NSManaged var media: Set<Media>

    /// Cached menu locations for this blog.
    /// - seealso: MenuLocation
    @NSManaged var menuLocations: NSOrderedSet//<MenuLocation>

    /// Cached menus for this blog.
    /// - seealso: Menu
    @NSManaged var menus: NSOrderedSet//<Menu>

    /// Cached posts for this blog. Includes both posts and pages.
    @NSManaged var posts: Set<AbstractPost>

    /// Settings for this blog, encapsulated in a BlogSettings instance
    /// - seealso: BlogSettings
    @NSManaged var settings: BlogSettings?

    /// Cached tags for this blog.
    @NSManaged var tags: Set<PostTag>

    /// Cached available themes for this blog.
    @NSManaged var themes: Set<Theme>
}
