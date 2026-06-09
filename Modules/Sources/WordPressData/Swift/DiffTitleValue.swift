import Foundation
import CoreData

@objc(DiffTitleValue)
public class DiffTitleValue: DiffAbstractValue {
    @NSManaged var revisionDiff: RevisionDiff?
}
