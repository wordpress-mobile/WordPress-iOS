import Foundation
import CoreData


extension UserAutocomplete {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserAutocomplete> {
        return NSFetchRequest<UserAutocomplete>(entityName: "UserAutocomplete")
    }

    @NSManaged public var displayName: String?
    @NSManaged public var username: String?
    @NSManaged public var imageURL: URL?
    @NSManaged public var autocompleter: Autocompleter?

}
