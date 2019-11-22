import Foundation
import Sentry

/**
WARNING: This class was created to track events of failures during
startup time. This will block the thread. Do not use unless you're sure.
*/
@objc class SentryStartupEvent: NSObject {
    static let shared = SentryStartupEvent()

    private var client: Client?

    private override init() {
        client = try? Client(dsn: ApiCredentials.sentryDSN())
    }

    @objc class func sharedInstance() -> SentryStartupEvent {
        return shared
    }

    @objc func send(title: String, errors: [NSError]) {
        var errors = errors
        let lastError = errors.removeLast()

        // Turn each error into a breadcrumb, except the last one
        for error in errors {
            let breadcrumb = Breadcrumb(level: .debug, category: error.domain)
            breadcrumb.message = "\(error.localizedDescription) | userInfo: \(lastError.userInfo)"
            client?.breadcrumbs.add(breadcrumb)
        }

        send(message: "\(title): error: \(lastError.localizedDescription) | domain: \(lastError.domain) | userInfo: \(lastError.userInfo)")
    }

    // Send the event and block the thread until it was actually sent
    @objc func send(message: String) {
        let semaphore = DispatchSemaphore(value: 0)

        let event = Event(level: .debug)
        event.message = message
        client?.send(event: event, completion: { _ in
            semaphore.signal()
        })

        semaphore.wait()
    }
}
