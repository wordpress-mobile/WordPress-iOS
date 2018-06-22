import Foundation
import CoreData

@objc (Page)
class Page: AbstractPost {
    /// Section identifier for the page, using the creation date.
    ///
    @objc func sectionIdentifierWithDateCreated() -> String {
        let date = date_created_gmt ?? Date()
        return date.toStringForPageSections()
    }

    /// Section identifier for the page, using the last modification date.
    ///
    @objc func sectionIdentifierWithDateModified() -> String {
        let date = dateModified ?? Date()
        return date.toStringForPageSections()
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

    override func featuredImageURLForDisplay() -> URL? {
        guard let path = pathForDisplayImage else {
            return nil
        }
        return URL(string: path)
    }
}
