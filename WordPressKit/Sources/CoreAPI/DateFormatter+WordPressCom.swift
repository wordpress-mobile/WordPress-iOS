import Foundation

extension DateFormatter {

    /// A `DateFormatter` configured to manage dates compatible with the WordPress.com API.
    ///
    /// - SeeAlso: [https://developer.wordpress.com/docs/api/](https://developer.wordpress.com/docs/api/)
    static let wordPressCom: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        return formatter
    }()
}
