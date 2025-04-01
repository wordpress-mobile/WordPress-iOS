import Foundation
import CocoaLumberjack

public class CustomLogFormatter: NSObject, DDLogFormatter {
    let logTimeStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public func format(message logMessage: DDLogMessage) -> String? {
        let timestamp = logTimeStampFormatter.string(from: logMessage.timestamp)
        let message = logMessage.message
        return ("\(timestamp) \(message)")
    }
}
