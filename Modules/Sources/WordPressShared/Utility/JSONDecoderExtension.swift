import Foundation

public extension JSONDecoder.DateDecodingStrategy {
    static var supportMultipleDateFormats: JSONDecoder.DateDecodingStrategy {
        return JSONDecoder.DateDecodingStrategy.custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            guard let calculatedDate = Date.dateFromServerDate(dateStr) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string \(dateStr)"
                )
            }

            return calculatedDate
        })
    }
}

private enum DateFormat: String, CaseIterable {
    case noTime = "yyyy-mm-dd"
    case dateWithTime = "yyyy-MM-dd HH:mm:ss"
    case iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
    case iso8601WithMilliseconds = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

    var formatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = rawValue
        return dateFormatter
    }
}

extension Date {
    public static func dateFromServerDate(_ string: String) -> Date? {
        var date: Date?
        for format in DateFormat.allCases {
            date = format.formatter.date(from: string)
            if date != nil {
                break
            }
        }
        return date
    }
}

extension NSDate {
    @objc public static func dateFromServerDate(_ string: String) -> Date? {
        Date.dateFromServerDate(string)
    }
}
