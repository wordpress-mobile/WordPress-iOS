import Foundation
import Sentry

/**
WARNING: This class was created to track events of failures during
startup time. This will block the thread. Do not use unless you're sure.
*/
@objc class SentryStartupEvent: NSObject {
    private var errors = [String]()

    func add(error: NSError, file: String = #file, function: String = #function, line: UInt = #line) {
        errors.append("\(function) (\(file):\(line)) \(error.localizedDescription) | userInfo: \(error.userInfo)")
    }

    @objc(addError:file:function:line:)
    func _objc_add(error: NSError, file: UnsafePointer<CChar>, function: UnsafePointer<CChar>, line: UInt) {
        add(error: error, file: String(cString: file), function: String(cString: function), line: line)
    }

    // Send the event and block the thread until it was actually sent
    @objc func send(title: String) {
        guard let client = try? Client(dsn: ApiCredentials.sentryDSN()) else {
            return
        }
        let semaphore = DispatchSemaphore(value: 0)
        let event = Event(level: .debug)
        let lastError = errors.removeLast()
        event.message = "\(title): \(lastError)"
        for error in errors {
            let breadcrumb = Breadcrumb(level: .debug, category: "Startup")
            breadcrumb.message = error
            client.breadcrumbs.add(breadcrumb)
        }
        client.send(event: event, completion: { _ in
            semaphore.signal()
        })

        semaphore.wait()
    }
}
