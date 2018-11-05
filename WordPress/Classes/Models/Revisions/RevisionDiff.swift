import Foundation
import CoreData


class RevisionDiff: NSManagedObject {
    @NSManaged var fromRevisionId: NSNumber
    @NSManaged var toRevisionId: NSNumber

    @NSManaged var totalAdditions: NSNumber
    @NSManaged var totalDeletions: NSNumber

    @NSManaged var contentDiffs: NSSet?
    @NSManaged var titleDiffs: NSSet?

    @NSManaged var revision: Revision?
}


// MARK: Generated accessors for contentDiffs
//
extension RevisionDiff {
    @objc(addContentDiffsObject:)
    @NSManaged public func addToContentDiffs(_ value: DiffContentValue)

    @objc(removeContentDiffsObject:)
    @NSManaged public func removeFromContentDiffs(_ value: DiffContentValue)

    @objc(addContentDiffs:)
    @NSManaged public func addToContentDiffs(_ values: NSSet)

    @objc(removeContentDiffs:)
    @NSManaged public func removeFromContentDiffs(_ values: NSSet)
}


// MARK: Generated accessors for titleDiffs
//
extension RevisionDiff {
    @objc(addTitleDiffsObject:)
    @NSManaged public func addToTitleDiffs(_ value: DiffTitleValue)

    @objc(removeTitleDiffsObject:)
    @NSManaged public func removeFromTitleDiffs(_ value: DiffTitleValue)

    @objc(addTitleDiffs:)
    @NSManaged public func addToTitleDiffs(_ values: NSSet)

    @objc(removeTitleDiffs:)
    @NSManaged public func removeFromTitleDiffs(_ values: NSSet)
}
