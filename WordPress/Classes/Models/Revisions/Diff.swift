import Foundation
import CoreData


class Diff: NSManagedObject {
    @NSManaged var fromRevisionId: NSNumber
    @NSManaged var toRevisionId: NSNumber

    @NSManaged var totalAdditions: NSNumber
    @NSManaged var totalDeletions: NSNumber

    @NSManaged var contentDiffs: [DiffContentValue]?
    @NSManaged var titleDiffs: [DiffAbstractValue]?

    @NSManaged var revision: Revision?
}
