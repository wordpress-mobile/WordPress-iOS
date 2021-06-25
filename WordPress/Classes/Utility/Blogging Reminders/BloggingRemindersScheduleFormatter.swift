import Foundation

struct BloggingRemindersScheduleFormatter {
    let schedule: BloggingRemindersScheduler.Schedule
    let calendar: Calendar

    init(schedule: BloggingRemindersScheduler.Schedule, calendar: Calendar? = nil) {
        self.schedule = schedule
        self.calendar = calendar ?? {
            var calendar = Calendar.current
            calendar.locale = Locale.autoupdatingCurrent
            return calendar
        }()
    }

    /// Description string of the current schedule for the specified blog.
    ///
    var shortIntervalDescription: String {
        switch schedule {
        case .none:
            return TextContent.shortNoRemindersDescription
        case .weekdays(let days):
            return Self.shortIntervalDescription(for: days.count)
        }
    }

    static func shortIntervalDescription(for days: Int) -> String {
        switch days {
        case 1:
            return NSLocalizedString("Once a week", comment: "Short title telling the user they will receive a blogging reminder once per week.")
        case 2:
            return NSLocalizedString("Twice a week", comment: "Short title telling the user they will receive a blogging reminder two times a week.")
        case 7:
            return NSLocalizedString("Every day", comment: "Short title telling the user they will receive a blogging reminder every day of the week.")
        default:
            return String(format: NSLocalizedString("%d times a week",
                                                    comment: "A short description of how many times a week the user will receive a blogging reminder. The placeholder will be populated with a count of the number of times a week they'll be reminded."), days)
        }
    }

    var longScheduleDescription: NSAttributedString {
        switch schedule {
        case .none:
            return NSAttributedString(string: TextContent.longNoRemindersDescription)
        case .weekdays(let days):
            // We want the days sorted by their localized index because under some locale configurations
            // Sunday is the first day of the week, whereas in some other localizations Monday comes first.
            let sortedDays = days.sorted { (first, second) -> Bool in
                let firstIndex = self.calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: first.rawValue)
                let secondIndex = self.calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: second.rawValue)

                return firstIndex < secondIndex
            }

            let markedUpDays: [String] = sortedDays.compactMap({ day in
                return "<strong>\(self.calendar.weekdaySymbols[day.rawValue])</strong>"
            })

            let text: String

            if days.count == 1 {
                text = String(format: TextContent.longNoRemindersDescriptionSingular, markedUpDays.first ?? "")
            } else {
                let formatter = ListFormatter()
                let formattedDays = formatter.string(from: markedUpDays) ?? ""
                text = String(format: TextContent.longNoRemindersDescriptionPlural, "<strong>\(days.count)</strong>", formattedDays)
            }

            let htmlData = NSString(string: text).data(using: String.Encoding.unicode.rawValue) ?? Data()
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html]

            let attributedString = (try? NSMutableAttributedString(data: htmlData,
                                                                   options: options,
                                                                   documentAttributes: nil)) ?? NSMutableAttributedString()

            // This loop applies the default font to the whole text, while keeping any symbolic attributes the previous font may
            // have had (such as bold style).
            attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length)) { (value, range, stop) in

                guard let oldFont = value as? UIFont,
                      let newDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                        .withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits) else {

                    return
                }

                let newFont = UIFont(descriptor: newDescriptor, size: 0)

                attributedString.addAttributes([.font: newFont], range: range)
            }

            return attributedString
        }
    }

    private enum TextContent {
        static let shortNoRemindersDescription = NSLocalizedString("None set", comment: "Title shown on table row where no blogging reminders have been set up yet")

        static let longNoRemindersDescription = NSLocalizedString("You have no reminders set.", comment: "Text shown to the user when setting up blogging reminders, if they complete the flow and have chosen not to add any reminders.")

        // Ideally we should use stringsdict to translate plurals, but GlotPress currently doesn't support this.
        static let longNoRemindersDescriptionSingular = NSLocalizedString("You'll get a reminder to blog <strong>once</strong> a week on %@.",
                                                              comment: "Blogging Reminders description confirming a user's choices. The placeholder will be replaced at runtime with a day of the week. The HTML markup is used to bold the word 'once'.")

        static let longNoRemindersDescriptionPlural = NSLocalizedString("You'll get reminders to blog %@ times a week on %@.",
                                                              comment: "Blogging Reminders description confirming a user's choices. The first placeholder will be populated with a count of the number of times a week they'll be reminded. The second will be a formatted list of days. For example: 'You'll get reminders to blog 2 times a week on Monday and Tuesday.")
    }
}
