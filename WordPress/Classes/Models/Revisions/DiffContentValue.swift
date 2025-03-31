import Foundation
import CoreData

public class DiffContentValue: DiffAbstractValue {
    @NSManaged var revisionDiff: RevisionDiff?
}
