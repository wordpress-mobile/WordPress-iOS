import Foundation


extension NSFetchedResultsController
{
    /// Returns an object of the specified type. Nil if the indexPath is out of bounds.
    ///
    func objectOfType<T : NSManagedObject>(type: T.Type, atIndexPath indexPath: NSIndexPath) -> T? {
        guard let sections = sections else {
            return nil
        }

        guard indexPath.section < sections.count && indexPath.row < sections[indexPath.section].numberOfObjects else {
            return nil
        }

        return objectAtIndexPath(indexPath) as? T
    }
}
