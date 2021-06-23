public enum LogEvent: String {
    case e = "[‼️]" // error
    case i = "[ℹ️]" // info
    case d = "[💬]" // debug
    case v = "[🔬]" // verbose
    case w = "[⚠️]" // warning
    case s = "[🔥]" // severe
}

// Usage examples:
//  Logger.log(message: "blogsPage.isLoaded()): \(blogsPage.isLoaded()))", event: .d)
//  Logger.log(message: "Hey ho, lets go!", event: .v)
// Output example:
//  2017-11-23 03:16:32025 [ℹ️][BasePage.swift]:18 19 waitForPage() -> Page AztecUITests.BlogsPage is loaded
public class Logger {
    // 1. The date formatter
    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS" // Use your own
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }

    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }

    public class func log(message: String, event: LogEvent,
                   fileName: String = #file, line: Int = #line,
                   column: Int = #column, funcName: String = #function) {
        #if DEBUG // 7.
            print("\(Date().toString()) \(event.rawValue)[\(sourceFileName(filePath: fileName))]:\(line) \(funcName) -> \(message)")
        #endif // 7.
    }
}

// 2. The Date to String extension
public extension Date {
    func toString() -> String {
        return Logger.dateFormatter.string(from: self as Date)
    }
}
