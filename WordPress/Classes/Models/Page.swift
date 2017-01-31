import Foundation
import CoreData

@objc (Page)
class Page: AbstractPost {
    /// Section identifier for the page, using the creation date.
    ///
    func sectionIdentifierWithDateCreated() -> String {
        let date = date_created_gmt ?? Date()
        return date.toStringForPageSections()
    }

    /// Section identifier for the page, using the last modification date.
    ///
    func sectionIdentifierWithDateModified() -> String {
        let date = dateModified ?? Date()
        return date.toStringForPageSections()
    }
}
