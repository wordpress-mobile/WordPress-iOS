import Foundation

struct TimeZoneFormatter {

    private let timeZoneOffsetFormatter = DateFormatter()

    private let timeAtTimeZoneFormatter = DateFormatter()

    private let date: Date

    init(currentDate: Date) {
        date = currentDate
        configureDateFormatter(timeZoneOffsetFormatter, timeStyle: .none, dateFormat: Constants.timeZoneOffsetFormat)
        configureDateFormatter(timeAtTimeZoneFormatter, timeStyle: .short, dateFormat: nil)
    }

    private func configureDateFormatter(_ formatter: DateFormatter, timeStyle: DateFormatter.Style, dateFormat: String?) {
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeStyle = timeStyle

        if let dateFormat = dateFormat {
            formatter.dateFormat = dateFormat
        }
    }

    func getZoneOffset(_ zone: WPTimeZone) -> String {
        guard let namedTimeZone = zone as? NamedTimeZone,
                let timeZone = TimeZone(identifier: namedTimeZone.value),
                let timeZoneLocalized = timeZone.localizedName(for: .standard, locale: .current) else {
            return ""
        }
        timeZoneOffsetFormatter.timeZone = timeZone

        let offset = timeZoneOffsetFormatter.string(from: date)
        return "\(timeZoneLocalized) (\(offset))"
    }

    func getTimeAtZone(_ zone: WPTimeZone) -> String {
        guard let namedTimeZone = zone as? NamedTimeZone,
              let timeZone = TimeZone(identifier: namedTimeZone.value) else {
            return ""
        }
        timeAtTimeZoneFormatter.timeZone = timeZone

        return timeAtTimeZoneFormatter.string(from: date)
    }
}

private extension TimeZoneFormatter {

    enum Constants {
        static let timeZoneOffsetFormat = "ZZZZ"
    }

}
