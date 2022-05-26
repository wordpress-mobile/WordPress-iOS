import Foundation
import CoreData
import WordPressKit

public class BloggingPromptSettingsReminderDays: NSManagedObject {

    convenience init(context: NSManagedObjectContext,
                     remoteReminderDays: RemoteBloggingPromptsSettings.ReminderDays) {
        self.init(context: context)
        self.monday = remoteReminderDays.monday
        self.tuesday = remoteReminderDays.tuesday
        self.wednesday = remoteReminderDays.wednesday
        self.thursday = remoteReminderDays.thursday
        self.friday = remoteReminderDays.friday
        self.saturday = remoteReminderDays.saturday
        self.sunday = remoteReminderDays.sunday
    }

}
