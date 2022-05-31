import Foundation
import CoreData

extension BloggingPromptSettingsReminderDays {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BloggingPromptSettingsReminderDays> {
        return NSFetchRequest<BloggingPromptSettingsReminderDays>(entityName: "BloggingPromptSettingsReminderDays")
    }

    @NSManaged public var monday: Bool
    @NSManaged public var tuesday: Bool
    @NSManaged public var wednesday: Bool
    @NSManaged public var thursday: Bool
    @NSManaged public var friday: Bool
    @NSManaged public var saturday: Bool
    @NSManaged public var sunday: Bool
    @NSManaged public var settings: BloggingPromptSettings?

}
