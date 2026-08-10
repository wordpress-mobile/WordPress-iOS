import Foundation
import Pulse
import Support

public final class PulseNetworkLogger: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {

    static let shared = PulseNetworkLogger(store: .shared)

    private static let sensitiveHeaders: Set<String> = [
        "Authorization",
        "Cookie",
        "Set-Cookie",
        "X-WP-Nonce"
    ]

    private let store: LoggerStore
    private let _logger: NetworkLogger
    // A request can be left incomplete in Pulse if logging is disabled while it is in flight.
    // This rare debug-only edge case does not justify tracking logging state for every task.
    private var logger: NetworkLogger? {
        ExtensiveLogging.enabled ? _logger : nil
    }

    static func forTesting(store: LoggerStore) -> PulseNetworkLogger {
        PulseNetworkLogger(store: store)
    }

    private init(store: LoggerStore) {
        self.store = store
        var configuration = NetworkLogger.Configuration()
        configuration.sensitiveHeaders = Self.sensitiveHeaders
        _logger = NetworkLogger(store: store, configuration: configuration)
        super.init()
    }

    func storeRequest(
        _ request: URLRequest,
        response: HTTPURLResponse?,
        error: (any Error)?,
        data: Data?
    ) {
        guard logger != nil else { return }

        var request = request
        request.allHTTPHeaderFields = Self.redactedHeaders(request.allHTTPHeaderFields)

        store.storeRequest(
            request,
            response: Self.redactedResponse(response),
            error: error,
            data: data
        )
    }

    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        logger?.logTaskCreated(task)
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        logger?.logTask(task, didFinishCollecting: metrics)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        logger?.logTask(task, didCompleteWithError: error)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        logger?.logDataTask(dataTask, didReceive: data)
    }

    private static func redactedResponse(_ response: HTTPURLResponse?) -> HTTPURLResponse? {
        guard let response, let url = response.url else { return nil }

        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, header in
            guard let name = header.key as? String else { return }
            result[name] = String(describing: header.value)
        }

        return HTTPURLResponse(
            url: url,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: redactedHeaders(headers)
        )
    }

    private static func redactedHeaders(_ headers: [String: String]?) -> [String: String]? {
        headers?
            .reduce(into: [:]) { result, header in
                let isSensitive = sensitiveHeaders.contains {
                    $0.caseInsensitiveCompare(header.key) == .orderedSame
                }
                result[header.key] = isSensitive ? "<private>" : header.value
            }
    }
}
