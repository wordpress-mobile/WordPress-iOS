import Foundation
import CoreData

extension BloggingPromptSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BloggingPromptSettings> {
        return NSFetchRequest<BloggingPromptSettings>(entityName: "BloggingPromptSettings")
    }

    @NSManaged public var isPotentialBloggingSite: Bool
    @NSManaged public var promptCardEnabled: Bool
    @NSManaged public var promptRemindersEnabled: Bool
    @NSManaged public var reminderTime: String?
    @NSManaged public var siteID: Int32
    @NSManaged public var reminderDays: BloggingPromptSettingsReminderDays?

}
