import Foundation

/// What the app has sent in a test, read from the log it writes when it runs against the fixtures.
struct RequestLog {
    /// A request the app made. The app writes these as `RecordedRequest`, in the `HTTPFixtures`
    /// module.
    struct Request: Decodable, CustomStringConvertible {
        let method: String
        let url: URL
        let body: String?
        let status: Int

        /// The mapping that answered the request, or `nil` when none matched.
        let fixture: String?

        var description: String {
            "\(status) \(method) \(url.absoluteString) \(fixture ?? "(no fixture)")"
        }
    }

    /// What a request is for, whatever its query: a method, a host and a path.
    struct Endpoint: Hashable, CustomStringConvertible {
        let method: String
        let host: String
        let path: String

        var description: String {
            "\(method) \(host)\(path)"
        }
    }

    let file: URL

    /// Every request the app has made, in order.
    func requests() throws -> [Request] {
        try String(contentsOf: file, encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
            // What follows the last line break is either nothing or a line the app is still writing.
            .dropLast()
            .map { try JSONDecoder().decode(Request.self, from: Data($0.utf8)) }
    }

    /// How many times the app has requested each endpoint.
    func requestCounts() throws -> [Endpoint: Int] {
        try requests()
            .reduce(into: [:]) { counts, request in
                let endpoint = Endpoint(
                    method: request.method,
                    host: request.url.host() ?? "",
                    path: request.url.path()
                )
                counts[endpoint, default: 0] += 1
            }
    }

    /// The analytics events the app has sent to Tracks, in the order it tracked them.
    ///
    /// The app queues the events it tracks and sends them in batches, so an event gets here some
    /// time after the action that caused it.
    func analyticsEvents() throws -> [AnalyticsEvent] {
        try requests()
            .filter { $0.url.path() == "/rest/v1.1/tracks/record" && (200..<300).contains($0.status) }
            .flatMap { try AnalyticsEvent.events(inBatch: $0.body ?? "") }
            .sorted { $0.date < $1.date }
    }
}

/// An analytics event the app sent to Tracks.
struct AnalyticsEvent: CustomStringConvertible {
    /// The event's name as Tracks receives it, which starts with the app's prefix:
    /// `jpios_stats_accessed`.
    let name: String

    /// When the app tracked the event. It sends it later, with the next batch.
    let date: Date

    /// The event's properties, with every value as text. They include the ones the app adds to
    /// every event to describe the user and the device.
    let properties: [String: String]

    /// The name, and the properties that are the event's own.
    var description: String {
        let ownProperties =
            properties
            .filter { !$0.key.hasPrefix("_") && !$0.key.hasPrefix("device_info_") }
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
        return ownProperties.isEmpty ? name : "\(name) <\(ownProperties.joined(separator: ", "))>"
    }

    /// The events in the body of a request to Tracks.
    static func events(inBatch body: String) throws -> [AnalyticsEvent] {
        let batch = try JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any]
        let sharedProperties = batch?["commonProps"] as? [String: Any] ?? [:]
        let events = batch?["events"] as? [[String: Any]] ?? []

        return events.compactMap { event in
            guard let name = event["_en"] as? String, let milliseconds = event["_ts"] as? Double else {
                return nil
            }
            // Tracks leaves out of an event the properties it has in common with its batch.
            let properties =
                sharedProperties
                .merging(event) { _, own in own }
                .filter { $0.key != "_en" && $0.key != "_ts" }
            return AnalyticsEvent(
                name: name,
                date: Date(timeIntervalSince1970: milliseconds / 1000),
                properties: properties.mapValues(text)
            )
        }
    }

    private static func text(_ value: Any) -> String {
        switch value {
        case let string as String: string
        case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID():
            number.boolValue ? "true" : "false"
        case let number as NSNumber: number.stringValue
        default: "\(value)"
        }
    }
}
