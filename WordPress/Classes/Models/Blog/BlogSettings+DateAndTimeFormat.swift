import Foundation

/// In this extension, we implement several nested Enums (and helper setters / getters) aimed at simplifying
/// the BlogSettings interface for handling writing date and time format properties.
///
extension BlogSettings {

    /// Enumerates the Date format settings.
    ///
    enum DateFormat: String {
        case MonthDY = "F j, Y"
        case YMD = "Y-m-d"
        case MDY = "m/d/Y"
        case DMY = "d/m/Y"

        /// Returns the sorted collection of all of the Localized Enum Titles.
        ///
        static var allTitles: [String] {
            return allValues.compactMap { descriptionMap[$0] }
        }

        /// Returns the sorted collection of all of the possible Enum Values.
        ///
        static var allValues: [String] {
            return [DateFormat.MonthDY.rawValue, DateFormat.YMD.rawValue,
                    DateFormat.MDY.rawValue, DateFormat.DMY.rawValue]
        }

        /// Returns the localized description of the current enum value.
        ///
        var description: String {
            return DateFormat.descriptionMap[rawValue]!
        }

        // MARK: - Private Properties

        fileprivate static let descriptionMap = [
            MonthDY.rawValue: NSLocalizedString("December 17, 2017", comment: "Only December needs to be translated"),
            YMD.rawValue: "2017-12-17",
            MDY.rawValue: "12/17/2017",
            DMY.rawValue: "17/12/2017"
        ]
    }

    var dateFormatDescription: String {
        guard let dateFormatEnum = DateFormat(rawValue: dateFormat) else {
            return dateFormat
        }
        return dateFormatEnum.description
    }

    /// Enumerates the Time format settings.
    ///
    enum TimeFormat: String {
        case ampmLowercase = "g:i a"
        case ampmUppercase = "g:i A"
        case twentyFourHours = "H:i"

        /// Returns the sorted collection of all of the Localized Enum Titles.
        /// Order is guarranteed to match exactly with *allValues*.
        ///
        static var allTitles: [String] {
            return allValues.compactMap { descriptionMap[$0] }
        }

        /// Returns the sorted collection of all of the possible Enum Values.
        ///
        static var allValues: [String] {
            return [TimeFormat.ampmLowercase.rawValue, TimeFormat.ampmUppercase.rawValue,
                    TimeFormat.twentyFourHours.rawValue]
        }

        /// Returns the localized description of the current enum value.
        ///
        var description: String {
            return TimeFormat.descriptionMap[rawValue]!
        }

        // MARK: - Private Properties

        fileprivate static let descriptionMap = [
            ampmLowercase.rawValue: "5:46 pm",
            ampmUppercase.rawValue: "5:46 PM",
            twentyFourHours.rawValue: "17:46",
        ]
    }

    var timeFormatDescription: String {
        guard let timeFormatEnum = TimeFormat(rawValue: timeFormat) else {
            return timeFormat
        }
        return timeFormatEnum.description
    }

    /// Enumerates the days of the week.
    ///
    enum DaysOfTheWeek: String {
        case Sunday = "0"
        case Monday = "1"
        case Tuesday = "2"
        case Wednesday = "3"
        case Thursday = "4"
        case Friday = "5"
        case Saturday = "6"

        /// Returns the sorted collection of all of the Localized Enum Titles.
        ///
        static var allTitles: [String] {
            return allValues.compactMap { descriptionMap[$0] }
        }

        /// Returns the sorted collection of all of the possible Enum Values.
        ///
        static var allValues: [String] {
            return descriptionMap.keys.sorted()
        }

        /// Returns the localized description of the current enum value.
        ///
        var description: String {
            return DaysOfTheWeek.descriptionMap[rawValue]!
        }

        // MARK: - Private Properties

        fileprivate static var weekdays: [String] {
            var calendar = Calendar.init(identifier: .gregorian)
            calendar.locale = Locale.current
            return calendar.weekdaySymbols
        }

        fileprivate static let descriptionMap = [
            Sunday.rawValue: weekdays[0],
            Monday.rawValue: weekdays[1],
            Tuesday.rawValue: weekdays[2],
            Wednesday.rawValue: weekdays[3],
            Thursday.rawValue: weekdays[4],
            Friday.rawValue: weekdays[5],
            Saturday.rawValue: weekdays[6]
        ]
    }

    var startOfWeekDescription: String {
        guard let dayOfWeekEnum = DaysOfTheWeek(rawValue: startOfWeek) else {
            return startOfWeek
        }
        return dayOfWeekEnum.description
    }
}
