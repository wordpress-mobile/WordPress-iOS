import Foundation
import CoreData

@objc(DiffContentValue)
public class DiffContentValue: DiffAbstractValue {
    @NSManaged var revisionDiff: RevisionDiff?
}
