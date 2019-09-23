import Foundation
import CoreData

@objc (Page)
class Page: AbstractPost {
    /// Returns if the Page has a visible parent Page
    @objc var hasVisibleParent: Bool = true

    /// The hierarchy index within a Pages list
    @objc var hierarchyIndex: Int = 0

    /// Returns if the Page is a top level
    @objc var isTopLevelPage: Bool {
        return parentID == nil
    }

    /// Returns if the Page can display some tag
    @objc var canDisplayTags: Bool {
        return hasPrivateState || hasPendingReviewState || hasLocalChanges()
    }

    /// Returns if the Page has private state
    @objc var hasPrivateState: Bool {
        return status == .publishPrivate
    }

    /// Returns if the Page has Pending Review state
    @objc var hasPendingReviewState: Bool {
        return status == .pending
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

    override func additionalContentHashes() -> [Data] {
        return [
            hash(for: parentID?.intValue ?? 0)
        ]
    }
}
