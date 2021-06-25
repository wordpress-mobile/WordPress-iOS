import Foundation

struct BloggingRemindersScheduleFormatter {
    let schedule: BloggingRemindersScheduler.Schedule

    /// Description string of the current schedule for the specified blog.
    ///
    var shortIntervalDescription: String {
        switch schedule {
        case .none:
            return NSLocalizedString("None set", comment: "Title shown on table row where no blogging reminders have been set up yet")
        case .weekdays(let days):
            switch days.count {
            case 1:
                return NSLocalizedString("Once a week", comment: "Short title telling the user they will receive a blogging reminder once per week.")
            case 2:
                return NSLocalizedString("Twice a week", comment: "Short title telling the user they will receive a blogging reminder two times a week.")
            case 7:
                return NSLocalizedString("Every day", comment: "Short title telling the user they will receive a blogging reminder every day of the week.")
            default:
                return String(format: NSLocalizedString("%d times a week",
                                                        comment: "A short description of how many times a week the user will receive a blogging reminder. The placeholder will be populated with a count of the number of times a week they'll be reminded."), days.count)
            }
        }
    }
}
