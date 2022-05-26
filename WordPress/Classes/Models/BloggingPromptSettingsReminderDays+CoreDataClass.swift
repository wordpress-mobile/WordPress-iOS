import Foundation
import CoreData
import WordPressKit

public class BloggingPromptSettingsReminderDays: NSManagedObject {

    func configure(with remoteReminderDays: RemoteBloggingPromptsSettings.ReminderDays) {
        self.monday = remoteReminderDays.monday
        self.tuesday = remoteReminderDays.tuesday
        self.wednesday = remoteReminderDays.wednesday
        self.thursday = remoteReminderDays.thursday
        self.friday = remoteReminderDays.friday
        self.saturday = remoteReminderDays.saturday
        self.sunday = remoteReminderDays.sunday
    }

    func getActiveWeekdays() -> [BloggingRemindersScheduler.Weekday] {
        return [
            sunday,
            monday,
            tuesday,
            wednesday,
            thursday,
            friday,
            saturday
        ].enumerated().flatMap { (index: Int, isReminderActive: Bool) in
            guard isReminderActive else {
                return nil
            }
            return BloggingRemindersScheduler.Weekday(rawValue: index)
        }
    }

}
