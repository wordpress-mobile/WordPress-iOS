import UIKit

class ImageDimensionsFetcher: NSObject, URLSessionDataDelegate {
    // Helpful typealiases for the closures
    public typealias CompletionHandler = (ImageDimensionFormat, CGSize?) -> Void
    public typealias ErrorHandler = (Error?) -> Void

    let completionHandler: CompletionHandler
    let errorHandler: ErrorHandler?

    // Internal use properties
    private let request: URLRequest
    private var task: URLSessionDataTask? = nil
    private let parser: ImageDimensionParser = ImageDimensionParser()

    init(request: URLRequest, success: @escaping CompletionHandler, error: ErrorHandler? = nil) {
        self.request = request
        self.completionHandler = success
        self.errorHandler = error

        super.init()
    }

    /// Starts the calculation process
    func start() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()

        self.task = task
    }

    func cancel() {
        task?.cancel()
    }

    // MARK: - URLSessionDelegate
    public func urlSession(_ session: URLSession, task dataTask: URLSessionTask, didCompleteWithError error: Error?) {
        // Don't trigger an error if we cancelled the task
        if let error = error, (error as NSError).code == NSURLErrorCancelled {
            return
        }

        self.errorHandler?(error)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Add the downloaded data to the parser
        parser.append(bytes: data)

        // Wait for the format to be detected
        guard let format = parser.format else {
            return
        }

        // Check if the format is unsupported
        guard format != .unsupported else {
            completionHandler(format, nil)

            // We can't parse unsupported images, cancel the download
            cancel()
            return
        }

        // Wait for the image size
        guard let size = parser.imageSize else {
            return
        }

        completionHandler(format, size)

        // The image size has been calculated, stop downloading
        cancel()
    }
}
