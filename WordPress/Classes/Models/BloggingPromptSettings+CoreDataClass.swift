import Foundation
import CoreData
import WordPressKit

public class BloggingPromptSettings: NSManagedObject {

    convenience init(context: NSManagedObjectContext,
                     siteID: Int32,
                     remoteSettings: RemoteBloggingPromptsSettings) {
        self.init(context: context)
        self.siteID = siteID
        self.promptCardEnabled = remoteSettings.promptCardEnabled
        self.reminderTime = remoteSettings.reminderTime
        self.promptRemindersEnabled = remoteSettings.promptRemindersEnabled
        self.isPotentialBloggingSite = remoteSettings.isPotentialBloggingSite
        self.reminderDays = BloggingPromptSettingsReminderDays(context: context,
                                                               remoteReminderDays: remoteSettings.reminderDays)
    }

}
