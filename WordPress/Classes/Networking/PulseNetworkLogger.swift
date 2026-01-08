import Foundation
import Pulse

public final class PulseNetworkLogger: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {

    private var logger: NetworkLogger? {
        FeatureFlag.pulse.enabled ? NetworkLogger.shared : nil
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
