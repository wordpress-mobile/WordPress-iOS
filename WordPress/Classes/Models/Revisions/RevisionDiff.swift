import Foundation
import CoreData

public class RevisionDiff: NSManagedObject {
    @NSManaged public var fromRevisionId: NSNumber
    @NSManaged public var toRevisionId: NSNumber

    @NSManaged public var totalAdditions: NSNumber
    @NSManaged public var totalDeletions: NSNumber

    @NSManaged public var contentDiffs: NSSet?
    @NSManaged public var titleDiffs: NSSet?

    @NSManaged public var revision: Revision?
}
