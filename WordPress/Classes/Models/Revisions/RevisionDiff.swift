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

    var contentToAttributedString: NSAttributedString? {
        return (contentDiffs?.operations ?? []).toAttributedString()
    }

    var titleToAttributedString: NSAttributedString? {
        return (titleDiffs?.operations ?? []).toAttributedString()
    }
}


private extension NSSet {
    var operations: [DiffAbstractValue]? {
        return allObjects as? [DiffAbstractValue]
    }
}
