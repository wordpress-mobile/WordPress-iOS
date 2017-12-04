import Foundation
import CoreData

protocol SectionIdentifiableByDate {
    /// Section identifier based on creation date.
    ///
    func sectionIdentifierWithDateCreated() -> String
    /// Section identifier based on last modification date.
    ///
    func sectionIdentifierWithDateModified() -> String
    /// Returns the selector string to use as a sectionNameKeyPath, depending on the given keyPath.
    ///
    static func sectionIdentifier(dateKeyPath: String) -> String
}

@objc (PortfolioProject)
class PortfolioProject: AbstractPost {}

extension PortfolioProject: SectionIdentifiableByDate {
    @objc func sectionIdentifierWithDateCreated() -> String {
        let date = date_created_gmt ?? Date()
        return date.toStringForPortfolioSections()
    }

    @objc func sectionIdentifierWithDateModified() -> String {
        let date = dateModified ?? Date()
        return date.toStringForPortfolioSections()
    }

    @objc static func sectionIdentifier(dateKeyPath: String) -> String {
        switch dateKeyPath {
        case #keyPath(AbstractPost.date_created_gmt):
            return NSStringFromSelector(#selector(PortfolioProject.sectionIdentifierWithDateCreated))
        case #keyPath(AbstractPost.dateModified):
            return NSStringFromSelector(#selector(PortfolioProject.sectionIdentifierWithDateModified))
        default:
            preconditionFailure("Invalid key path for a section identifier")
        }
    }
}
