import Foundation

/// RFC339NoTimeDateFormatter works with yyyy-MM-dd dates with no time
/// RFC-3339 format requires to use UTC time zone to avoid unexpected issues during conversions
/// However, when we turn yyyy-MM-dd string into date using UTC time zone, it may appear as a different date
/// for other time zones.
/// RFC339NoTimeDateFormatter ensures that the date is converted to local time zone before returning.
///
final class RFC339NoTimeDateFormatter: DateFormatter {
    private let currentTimeZone: TimeZone

    init(currentTimeZone: TimeZone = .current) {
        self.currentTimeZone = currentTimeZone
        super.init()

        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// RFC-3339 standard requires to have
    /// en_US_POSIX locale
    /// and UTC time `one
    /// otherwise there can be problems with date conversions
    private func commonInit() {
        locale = Locale(identifier: "en_US_POSIX")
        dateFormat = "yyyy-MM-dd"
        timeZone = .init(secondsFromGMT: 0)
    }

    /// Returns a date which is shifted based on local time zone
    override func date(from string: String) -> Date? {
        guard let dateInUTC = super.date(from: string) else {
            return nil
        }

        let secondsFromGMT = TimeInterval(currentTimeZone.secondsFromGMT(for: dateInUTC))
        let localDate = dateInUTC.addingTimeInterval(-secondsFromGMT)

        return localDate
    }

    override func string(from date: Date) -> String {
        let secondsFromGMT = TimeInterval(currentTimeZone.secondsFromGMT(for: date))
        let utcDate = date.addingTimeInterval(secondsFromGMT)

        return super.string(from: utcDate)
    }
}
