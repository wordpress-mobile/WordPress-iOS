import Foundation
import CoreData


extension Autocompleter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Autocompleter> {
        return NSFetchRequest<Autocompleter>(entityName: "Autocompleter")
    }

    @NSManaged public var siteID: NSNumber?
    @NSManaged public var userAutocompletes: NSSet?

}

// MARK: Generated accessors for userAutocompletes
extension Autocompleter {

    @objc(addUserAutocompletesObject:)
    @NSManaged public func addToUserAutocompletes(_ value: UserAutocomplete)

    @objc(removeUserAutocompletesObject:)
    @NSManaged public func removeFromUserAutocompletes(_ value: UserAutocomplete)

    @objc(addUserAutocompletes:)
    @NSManaged public func addToUserAutocompletes(_ values: NSSet)

    @objc(removeUserAutocompletes:)
    @NSManaged public func removeFromUserAutocompletes(_ values: NSSet)

}
