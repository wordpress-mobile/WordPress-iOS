import Foundation
import CoreData

extension ReaderCard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReaderCard> {
        return NSFetchRequest<ReaderCard>(entityName: "ReaderCard")
    }

    @NSManaged public var sortRank: Double
    @NSManaged public var post: ReaderPost?
    @NSManaged public var topics: NSOrderedSet?
    @NSManaged public var sites: NSOrderedSet?

}
