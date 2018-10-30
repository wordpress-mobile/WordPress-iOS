import Foundation
import CoreData


class DiffContentValue: DiffAbstractValue {
    @NSManaged var revisionDiff: Diff?
}
