import Foundation
import WordPressKit

enum PostStatus: String {
    case draft    = "draft"
    case publish  = "publish"
}

enum PostType: String, CaseIterable {
    case post = "post"
    case page = "page"

    var title: String {
        switch self {
        case .post: return AppLocalizedString("Post", comment: "Title shown when selecting a post type of Post from the Share Extension.")
        case .page: return AppLocalizedString("Page", comment: "Title shown when selecting a post type of Page from the Share Extension.")
        }
    }
}

/// ShareData is a state container for the share extension screens.
///
@objc
class ShareData: NSObject {

    /// Selected Site's ID
    ///
    var selectedSiteID: Int?

    /// Selected Site's Name
    ///
    var selectedSiteName: String?

    /// Post's Title
    ///
    var title = ""

    /// Post's Content
    ///
    var contentBody = ""

    /// Post's status, set to publish by default
    ///
    var postStatus: PostStatus = .publish

    /// Post's type, set to post by default
    ///
    var postType: PostType = .post

    /// Dictionary of URLs mapped to attachment ID's
    ///
    var sharedImageDict = [URL: String]()

    /// Comma-delimited list of tags for post
    ///
    var tags: String?

    /// Default category ID for selected site
    ///
    var defaultCategoryID: NSNumber?

    /// Default category name for selected site
    ///
    var defaultCategoryName: String?

    /// Selected post categories (IDs and Names)
    ///
    var userSelectedCategories: [RemotePostCategory]?

    /// All categories for the selected site
    ///
    var allCategoriesForSelectedSite: [RemotePostCategory]?

    // MARK: - Computed Vars

    /// Total number of categories for selected site
    ///
    var categoryCountForSelectedSite: Int {
        return allCategoriesForSelectedSite?.count ?? 0
    }

    /// Computed (read-only) var that returns a comma-delimited string of selected category names. If
    /// selected categories is empty then return the default category name. Otherwise return "".
    ///
    var selectedCategoriesNameString: String {
        guard let selectedCategories = userSelectedCategories, !selectedCategories.isEmpty else {
            return defaultCategoryName ?? ""
        }

        return selectedCategories.map({ $0.name }).joined(separator: ", ")
    }

    /// Computed (read-only) var that returns a comma-delimited string of selected category IDs
    ///
    var selectedCategoriesIDString: String? {
        guard let selectedCategories = userSelectedCategories, !selectedCategories.isEmpty else {
            return nil
        }

        return selectedCategories.map({ $0.categoryID.stringValue }).joined(separator: ", ")
    }

    // MARK: - Helper Functions

    /// Helper function to set both the default category.
    ///
    func setDefaultCategory(categoryID: NSNumber, categoryName: String) {
        defaultCategoryID = categoryID
        defaultCategoryName = categoryName
    }

    /// Clears out all category information
    ///
    func clearCategoryInfo() {
        defaultCategoryID = nil
        defaultCategoryName = nil
        allCategoriesForSelectedSite = nil
        userSelectedCategories = nil
    }
}
