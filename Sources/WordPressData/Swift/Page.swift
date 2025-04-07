import Foundation
import CoreData

@objc(Page)
public class Page: AbstractPost {
    /// Returns if the Page has a visible parent Page
    @objc public var hasVisibleParent: Bool = true

    /// The hierarchy index within a Pages list
    @objc public var hierarchyIndex: Int = 0

    /// Returns if the Page is a top level
    @objc var isTopLevelPage: Bool {
        return parentID == nil
    }

    /// Section identifier for the page, using the creation date.
    ///
    @objc func sectionIdentifierWithDateCreated() -> String {
        let date = date_created_gmt ?? Date()
        return date.longUTCStringWithoutTime()
    }

    /// Section identifier for the page, using the last modification date.
    ///
    @objc func sectionIdentifierWithDateModified() -> String {
        let date = dateModified ?? Date()
        return date.longUTCStringWithoutTime()
    }

    /// Returns the selector string to use as a sectionNameKeyPath, depending on the given keyPath.
    ///
    @objc static func sectionIdentifier(dateKeyPath: String) -> String {
        switch dateKeyPath {
        case #keyPath(AbstractPost.date_created_gmt):
            return NSStringFromSelector(#selector(Page.sectionIdentifierWithDateCreated))
        case #keyPath(AbstractPost.dateModified):
            return NSStringFromSelector(#selector(Page.sectionIdentifierWithDateModified))
        default:
            preconditionFailure("Invalid key path for a section identifier")
        }
    }

    // MARK: - Homepage Settings

    @objc public var isSiteHomepage: Bool {
        guard let postID,
            let homepageID = blog.homepagePageID,
            let homepageType = blog.homepageType,
            homepageType == .page else {
            return false
        }

        return homepageID == postID.intValue
    }

    @objc public var isSitePostsPage: Bool {
        guard let postID,
            let postsPageID = blog.homepagePostsPageID,
            let homepageType = blog.homepageType,
            homepageType == .page else {
            return false
        }

        return postsPageID == postID.intValue
    }
}
