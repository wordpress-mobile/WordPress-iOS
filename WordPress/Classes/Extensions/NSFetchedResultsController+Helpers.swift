import Foundation


extension NSFetchedResultsController {
    /// Returns whether an indexPath represents the last row in it's section, or not
    ///
    func isLastIndexPathInSection(_ indexPath: IndexPath) -> Bool {
        guard let sections = sections else {
            return false
        }

        guard indexPath.section < sections.count else {
            return false
        }

        return indexPath.row == sections[indexPath.section].numberOfObjects - 1
    }

/*
     Nuked for Swift 3 migration, see: https://swift.org/migration-guide/
     Ref: "Objective-C lightweight generic classes are now imported as generic types"
     - Brent Nov 28/16

    /// Returns an object of the specified type. Nil if the indexPath is out of bounds.
    ///
    func objectOfType<T : NSManagedObject>(_ type: T.Type, atIndexPath indexPath: IndexPath) -> T? {
        guard let sections = sections else {
            return nil
        }

        guard indexPath.section < sections.count else {
            return nil
        }

        guard indexPath.row < sections[indexPath.section].numberOfObjects && indexPath.row >= 0 else {
            return nil
        }

        return object(at: indexPath) as? T
    }
*/
}
