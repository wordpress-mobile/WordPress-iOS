import Foundation
import CoreData

@objc public class ReaderSearchSuggestion : NSManagedObject
{
    @NSManaged public var date: NSDate?
    @NSManaged public var searchPhrase: String
}
