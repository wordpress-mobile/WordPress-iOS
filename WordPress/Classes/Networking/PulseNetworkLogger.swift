import Foundation
import Pulse
import Support

public final class PulseNetworkLogger: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {

    private let _logger: NetworkLogger
    private var logger: NetworkLogger? {
        ExtensiveLogging.enabled ? _logger : nil
    }

    override public init() {
        var configuration = NetworkLogger.Configuration()
        configuration.sensitiveHeaders = [
            "Authorization",
            "Cookie",
            "Set-Cookie",
            "X-WP-Nonce"
        ]
        _logger = NetworkLogger(configuration: configuration)
        super.init()
    }

    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        logger?.logTaskCreated(task)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        logger?.logTask(task, didFinishCollecting: metrics)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        logger?.logTask(task, didCompleteWithError: error)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        logger?.logDataTask(dataTask, didReceive: data)
    }

}
