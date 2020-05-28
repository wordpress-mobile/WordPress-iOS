import Foundation
import AutomatticTracks
import Sentry

private struct ErrorWithCaller {
    let error: NSError
    let caller: String
}

/**
WARNING: This class was created to track events of failures during
startup time. This will block the thread. Do not use unless you're sure.
*/
@objc class SentryStartupEvent: NSObject {
    private typealias UserInfo = [String: Any]

    private var errors = [ErrorWithCaller]()

    func add(error: NSError, file: String = #file, function: String = #function, line: UInt = #line) {
        let filename = (file as NSString).lastPathComponent

        errors.append(ErrorWithCaller(error: error, caller: "\(function) (\(filename):\(line))"))
    }

    func add(error: Error, file: String = #file, function: String = #function, line: UInt = #line) {
        add(error: error as NSError, file: file, function: function, line: line)
    }

    @objc(addError:file:function:line:)
    func _objc_add(error: NSError, file: UnsafePointer<CChar>, function: UnsafePointer<CChar>, line: UInt) {
        add(error: error, file: String(cString: file), function: String(cString: function), line: line)
    }

    // Send the event and block the thread until it was actually sent
    @objc func send(title: String) {
        let userInfo = errors.enumerated().reduce(into: [String: Any](), { (result, arg1) in
            let (index, errorWithCaller) = arg1
            let error = errorWithCaller.error
            result["Error \(index + 1)"] = [
                "Method": errorWithCaller.caller,
                "Domain": error.domain,
                "Code": error.code,
                "Description": error.localizedDescription,
                "User Info": error.userInfo.description
            ]
        })

        CrashLogging.logErrorAndWait(NSError(domain: title, code: -1, userInfo: [NSLocalizedDescriptionKey: title]), userInfo: userInfo)
    }
}

extension CrashLogging {
    /**
     Writes the error to the Crash Logging system, and includes a stack trace. This method will block the thread until the event is fired.

     - Parameters:
     - error: The error object
     - userInfo: A dictionary containing additional data about this error.
     - level: The level of severity to report in Sentry (`.error` by default)
    */
    static func logErrorAndWait(_ error: Error, userInfo: [String: Any]? = nil, level: SentrySeverity = .error) {
        let event = Event(level: .error)
        event.message = error.localizedDescription
        event.extra = userInfo ?? (error as NSError).userInfo

        Client.shared?.snapshotStacktrace {
            Client.shared?.appendStacktrace(to: event)
        }

        guard let client = Client.shared else {
           return
        }

        let semaphore = DispatchSemaphore(value: 0)

        client.send(event: event) { _ in
            semaphore.signal()
        }

        semaphore.wait()
    }
}
