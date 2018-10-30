import Foundation
import CoreData


class RevisionDiff: NSManagedObject {
    @NSManaged var fromRevisionId: NSNumber
    @NSManaged var toRevisionId: NSNumber

    @NSManaged var totalAdditions: NSNumber
    @NSManaged var totalDeletions: NSNumber

    @NSManaged var contentDiffs: [RevisionDiffContentValue]?
    @NSManaged var titleDiffs: [RevisionDiffAbstractValue]?

    @NSManaged var revision: Revision?
}
