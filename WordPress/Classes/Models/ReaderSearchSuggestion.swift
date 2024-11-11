import Foundation
import CoreData

@available(*, deprecated, message: "No longer used")
@objc open class ReaderSearchSuggestion: NSManagedObject {
    @NSManaged open var date: Date?
    @NSManaged open var searchPhrase: String
}
