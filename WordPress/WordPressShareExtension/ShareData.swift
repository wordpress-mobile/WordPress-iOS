import Foundation

enum PostStatus: String {
    case draft    = "draft"
    case publish  = "publish"
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
    var selectedCategories: [[NSNumber: String]]?

    /// Total number of categories on selected site
    ///
    var totalCategoryCount: Int = 0

    /// Computed (read-only) var that returns a comma-delimted string of selected categories
    ///
    var selectedCategoriesString: String {
        guard let selectedCategories = selectedCategories, !selectedCategories.isEmpty else {
            return ""
        }

        let categoryNames = selectedCategories.flatMap {
            category in category.map { $0.value }
        }
        return categoryNames.joined(separator: ", ")
    }

    /// Helper function to set both the default category as well as the selected category in one shot.
    ///
    func setDefaultCategory(categoryID: NSNumber, categoryName: String) {
        defaultCategoryID = categoryID
        defaultCategoryName = categoryName
        selectedCategories = [[categoryID: categoryName]]
    }

    /// Clears out all category information
    ///
    func clearCategoryInfo() {
        defaultCategoryID = nil
        defaultCategoryName = nil
        selectedCategories = nil
        totalCategoryCount = 0
    }
}
