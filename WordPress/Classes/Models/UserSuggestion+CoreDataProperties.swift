import Foundation
import CoreData


extension UserSuggestion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSuggestion> {
        return NSFetchRequest<UserSuggestion>(entityName: "UserSuggestion")
    }

    @NSManaged public var displayName: String?
    @NSManaged public var imageURL: URL?
    @NSManaged public var username: String?
    @NSManaged public var blog: Blog?
}
