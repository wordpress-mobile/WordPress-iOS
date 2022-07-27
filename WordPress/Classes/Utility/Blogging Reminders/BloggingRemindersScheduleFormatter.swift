import Foundation

struct BloggingRemindersScheduleFormatter {
    private let calendar: Calendar

    init(calendar: Calendar? = nil) {
        self.calendar = calendar ?? {
            var calendar = Calendar.current
            calendar.locale = Locale.autoupdatingCurrent
            return calendar
        }()
    }

    /// Attributed short description string of the current schedule for the specified blog.
    ///
    func shortScheduleDescription(for schedule: BloggingRemindersScheduler.Schedule, time: String? = nil) -> NSAttributedString {
        switch schedule {
        case .none:
            return Self.stringToAttributedString(TextContent.shortNoRemindersDescription)
        case .weekdays(let days):
            guard days.count > 0 else {
                return shortScheduleDescription(for: .none, time: time)
            }

            return Self.shortScheduleDescription(for: days.count, time: time)
        }
    }

    /// Attributed long description string of the current schedule for the specified blog.
    ///
    func longScheduleDescription(for schedule: BloggingRemindersScheduler.Schedule, time: String) -> NSAttributedString {
        switch schedule {
        case .none:
            return NSAttributedString(string: TextContent.longNoRemindersDescription)
        case .weekdays(let days):
            guard days.count > 0 else {
                return longScheduleDescription(for: .none, time: time)
            }

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
                text = String(format: TextContent.oneReminderLongDescriptionWithTime, markedUpDays.first ?? "", "<strong>\(time)</strong>")
            } else {
                let formatter = ListFormatter()
                let formattedDays = formatter.string(from: markedUpDays) ?? ""
                text = String(format: TextContent.manyRemindersLongDescriptionWithTime, "<strong>\(days.count)</strong>", formattedDays, "<strong>\(time)</strong>")
            }

            return Self.stringToAttributedString(text)
        }
    }


}

// MARK: - Private type methods and properties
private extension BloggingRemindersScheduleFormatter {

    static func shortScheduleDescription(for days: Int, time: String?) -> NSAttributedString {
        guard let time = time else {
            return shortScheduleDescription(for: days)
        }
        return shortScheduleDescriptionWithTime(for: days, time: time)
    }

    static func shortScheduleDescriptionWithTime(for days: Int, time: String) -> NSAttributedString {
        let text: String = {
            switch days {
            case 1:
                return String(format: TextContent.oneReminderShortDescriptionWithTime, time)
            case 2:
                return String(format: TextContent.twoRemindersShortDescriptionWithTime, time)
            case 7:
                return "<strong>" + String(format: TextContent.everydayRemindersShortDescriptionWithTime, time) + "</strong>"
            default:
                return String(format: TextContent.manyRemindersShortDescriptionWithTime, days, time)
            }
        }()

        return Self.stringToAttributedString(text)
    }

    static func shortScheduleDescription(for days: Int) -> NSAttributedString {

        let text: String = {
            switch days {
            case 1:
                return TextContent.oneReminderShortDescription
            case 2:
                return TextContent.twoRemindersShortDescription
            case 7:
                return "<strong>" + TextContent.everydayRemindersShortDescription + "</strong>"
            default:
                return String(format: TextContent.manyRemindersShortDescription, days)
            }
        }()

        return Self.stringToAttributedString(text)
    }

    static func stringToAttributedString(_ string: String) -> NSAttributedString {
        let htmlData = NSString(string: string).data(using: String.Encoding.unicode.rawValue) ?? Data()
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

    enum TextContent {
        static let shortNoRemindersDescription = NSLocalizedString("None set", comment: "Title shown on table row where no blogging reminders have been set up yet")

        static let longNoRemindersDescription = NSLocalizedString("You have no reminders set.", comment: "Text shown to the user when setting up blogging reminders, if they complete the flow and have chosen not to add any reminders.")

        // Ideally we should use stringsdict to translate plurals, but GlotPress currently doesn't support this.
        static let oneReminderLongDescriptionWithTime = NSLocalizedString("You'll get a reminder to blog <strong>once</strong> a week on %@ at %@.",
                                                              comment: "Blogging Reminders description confirming a user's choices. The placeholder will be replaced at runtime with a day of the week. The HTML markup is used to bold the word 'once'.")

        static let manyRemindersLongDescriptionWithTime = NSLocalizedString("You'll get reminders to blog %@ times a week on %@.",
                                                              comment: "Blogging Reminders description confirming a user's choices. The first placeholder will be populated with a count of the number of times a week they'll be reminded. The second will be a formatted list of days. For example: 'You'll get reminders to blog 2 times a week on Monday and Tuesday.")

        static let oneReminderShortDescriptionWithTime = NSLocalizedString("<strong>Once</strong> a week at %@",
                                                                            comment: "Short title telling the user they will receive a blogging reminder once per week. The word for 'once' should be surrounded by <strong> HTML tags.")

        static let twoRemindersShortDescriptionWithTime = NSLocalizedString("<strong>Twice</strong> a week at %@",
                                                                            comment: "Short title telling the user they will receive a blogging reminder two times a week. The word for 'twice' should be surrounded by <strong> HTML tags.")

        static let manyRemindersShortDescriptionWithTime = NSLocalizedString("<strong>%d</strong> times a week at %@",
                                                                             comment: "A short description of how many times a week the user will receive a blogging reminder. The '%d' placeholder will be populated with a count of the number of times a week they'll be reminded, and should be surrounded by <strong> HTML tags.")

        static let everydayRemindersShortDescriptionWithTime = NSLocalizedString("Every day at %@",
                                                                                 comment: "Short title telling the user they will receive a blogging reminder every day of the week.")

        static let oneReminderShortDescription = NSLocalizedString("<strong>Once</strong> a week",
                                                                            comment: "Short title telling the user they will receive a blogging reminder once per week. The word for 'once' should be surrounded by <strong> HTML tags.")

        static let twoRemindersShortDescription = NSLocalizedString("<strong>Twice</strong> a week",
                                                                            comment: "Short title telling the user they will receive a blogging reminder two times a week. The word for 'twice' should be surrounded by <strong> HTML tags.")

        static let manyRemindersShortDescription = NSLocalizedString("<strong>%d</strong> times a week",
                                                                             comment: "A short description of how many times a week the user will receive a blogging reminder. The '%d' placeholder will be populated with a count of the number of times a week they'll be reminded, and should be surrounded by <strong> HTML tags.")

        static let everydayRemindersShortDescription = NSLocalizedString("Every day",
                                                                                 comment: "Short title telling the user they will receive a blogging reminder every day of the week.")
    }
}
