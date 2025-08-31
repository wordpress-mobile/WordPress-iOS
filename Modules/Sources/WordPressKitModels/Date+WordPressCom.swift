import Foundation

extension Date {

    /// Parses a date string
    ///
    /// Dates in the format specified in http://www.w3.org/TR/NOTE-datetime should be OK.
    /// The kind of dates returned by the REST API should match that format, even if the doc promises ISO 8601.
    ///
    /// Parsing the full ISO 8601, or even RFC 3339 is more complex than this, and makes no sense right now.
    ///
    /// - SeeAlso: [WordPress.com REST API docs](https://developer.wordpress.com/docs/api/)
    /// - Warning: This method doesn't support fractional seconds or dates with leap seconds (23:59:60 turns into 23:59:00)
    static func with(wordPressComJSONString jsonString: String) -> Date? {
        DateFormatter.wordPressCom.date(from: jsonString)
    }

    var wordPressComJSONString: String {
        DateFormatter.wordPressCom.string(from: self)
    }
}
