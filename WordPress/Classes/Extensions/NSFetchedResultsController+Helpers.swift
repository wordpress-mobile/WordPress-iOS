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

    /// Returns the NSManagedObject at the specified indexPath, if the Row + Section are still valid.
    /// Otherwise, null will be returned.
    ///
    func managedObject(atUnsafe indexPath: IndexPath) -> NSManagedObject? {
        guard let sections = sections else {
            return nil
        }

        guard indexPath.section < sections.count else {
            return nil
        }

        guard indexPath.row < sections[indexPath.section].numberOfObjects && indexPath.row >= 0 else {
            return nil
        }

        return object(at: indexPath) as? NSManagedObject
    }
}
