import Foundation
import CoreData


extension AtMentionSuggestion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AtMentionSuggestion> {
        return NSFetchRequest<AtMentionSuggestion>(entityName: "AtMentionSuggestion")
    }

    @NSManaged public var displayName: String?
    @NSManaged public var imageURL: URL?
    @NSManaged public var username: String?
    @NSManaged public var blog: Blog?
}
