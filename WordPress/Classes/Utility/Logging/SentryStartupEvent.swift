import Foundation
import Sentry

/**
WARNING: This class was created to track events of failures during
startup time. This will block the thread. Do not use unless you're sure.
*/
@objc class SentryStartupEvent: NSObject {
    private typealias UserInfo = [String: Any]
    private typealias ErrorWithInfo = (String, UserInfo)

    private var errors = [ErrorWithInfo]()

    func add(error: NSError, file: String = #file, function: String = #function, line: UInt = #line) {
        let filename = (file as NSString).lastPathComponent
        let info: UserInfo = [
            "Description": error.description,   // Intentionally not using `localizedDescription`, as it helps to have error in Sentry in a single language
            "User Info": error.userInfo
        ]

        errors.append(("\(function) (\(filename):\(line))", info))
    }

    @objc(addError:file:function:line:)
    func _objc_add(error: NSError, file: UnsafePointer<CChar>, function: UnsafePointer<CChar>, line: UInt) {
        add(error: error, file: String(cString: file), function: String(cString: function), line: line)
    }

    // Send the event and block the thread until it was actually sent
    @objc func send(title: String) {
        guard !WPAppAnalytics.userHasOptedOut(),
            let client = try? Client(dsn: ApiCredentials.sentryDSN()) else {
            return
        }
        let semaphore = DispatchSemaphore(value: 0)
        let event = Event(level: .debug)
        event.message = title

        event.extra = errors.enumerated().reduce(into: [String: Any](), { (result, arg1) in
            let (index, error) = arg1
            let (message, info) = error
            result["Error \(index + 1)"] = [
                "Method": message,
                "Error": info.description,
            ]
        })

        client.send(event: event, completion: { _ in
            semaphore.signal()
        })

        semaphore.wait()
    }
}
