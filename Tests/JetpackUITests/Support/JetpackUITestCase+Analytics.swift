import XCTest

extension JetpackUITestCase {
    struct AnalyticsEventNotSentError: Error, CustomStringConvertible {
        let name: String
        let properties: [String: String]
        let timeout: TimeInterval
        let sent: [AnalyticsEvent]

        var description: String {
            let expected = properties.isEmpty ? name : "\(name) with \(properties)"
            let sent = sent.map(\.description).joined(separator: "\n")
            return "\(expected) was not sent within \(timeout) seconds. The app sent:\n\(sent)"
        }
    }

    /// How long to wait for an analytics event unless told otherwise.
    ///
    /// The app queues the events it tracks and sends them every 15 seconds, so an event can take
    /// that long to leave the app.
    static let analyticsEventTimeout: TimeInterval = 30

    /// The analytics events the app has tracked since it launched for this test and has sent to
    /// Tracks, in the order it tracked them.
    ///
    /// These are read from the app's requests, so they're what Tracks would have received. Only a
    /// suite on the fixtures backend can read them: against a real account they go to Tracks.
    func sentAnalyticsEvents() throws -> [AnalyticsEvent] {
        guard let requestLog else {
            throw RequestLogUnavailableError()
        }
        // The app also sends the events an earlier launch tracked and didn't get to send.
        return try requestLog.analyticsEvents().filter { $0.date >= launchDate }
    }

    /// Waits for the app to send an analytics event, and returns the most recent one.
    ///
    /// - Parameters:
    ///   - name: The event's name as Tracks receives it, with the app's prefix.
    ///   - properties: Properties the event has to have. It may have others.
    @discardableResult
    func waitForAnalyticsEvent(
        _ name: String,
        properties: [String: String] = [:],
        timeout: TimeInterval = analyticsEventTimeout
    ) throws -> AnalyticsEvent {
        try XCTContext.runActivity(named: "Wait for the analytics event \(name)") { _ in
            let deadline = Date(timeIntervalSinceNow: timeout)
            while true {
                let events = try sentAnalyticsEvents()
                let match = events.last { event in
                    event.name == name && properties.allSatisfy { event.properties[$0.key] == $0.value }
                }
                if let match {
                    return match
                }
                guard Date() < deadline else {
                    throw AnalyticsEventNotSentError(name: name, properties: properties, timeout: timeout, sent: events)
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
}
