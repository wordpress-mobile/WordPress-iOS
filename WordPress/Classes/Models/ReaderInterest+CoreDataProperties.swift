import Foundation
import CoreData

extension ReaderInterest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReaderInterest> {
        return NSFetchRequest<ReaderInterest>(entityName: "ReaderInterest")
    }

    @NSManaged public var title: String?
    @NSManaged public var slug: String?
    @NSManaged public var card: ReaderCard?

}
