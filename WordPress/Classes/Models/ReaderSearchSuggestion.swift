import Foundation
import CoreData

@objc open class ReaderSearchSuggestion: NSManagedObject {
    @NSManaged open var date: Date?
    @NSManaged open var searchPhrase: String
}
