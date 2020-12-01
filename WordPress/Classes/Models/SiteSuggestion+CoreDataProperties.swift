import Foundation
import CoreData


extension SiteSuggestion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SiteSuggestion> {
        return NSFetchRequest<SiteSuggestion>(entityName: "SiteSuggestion")
    }

    @NSManaged public var title: String?
    @NSManaged public var siteURL: URL?
    @NSManaged public var subdomain: String?
    @NSManaged public var blavatarURL: URL?
    @NSManaged public var blog: Blog?

}
