import Foundation
import Sentry

// - WARNING: This class was created to track events of failures during
// startup time. This will block the thread. Do not use unless you're sure.
@objc class SentryStartupEvent: NSObject {
    static let shared = SentryStartupEvent()

    private var client: Client?

    private override init() {
        client = try? Client(dsn: ApiCredentials.sentryDSN())
    }

    @objc class func sharedInstance() -> SentryStartupEvent {
        return shared
    }

    @objc func send(title: String, error: NSError) {
        send(message: "\(title): error: \(error.localizedDescription) | domain: \(error.domain) | userInfo: \(error.userInfo)")
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
