import Foundation
import Combine

public typealias WordPressAPIResult<Response, Error: LocalizedError> = Result<Response, WordPressAPIError<Error>>

public struct HTTPAPIResponse<Body> {
    public var response: HTTPURLResponse
    public var body: Body
}

extension HTTPAPIResponse where Body == Data {
    var bodyText: String? {
        var encoding: String.Encoding?
        if let charset = response.textEncodingName {
            encoding = String.Encoding(ianaCharsetName: charset)
        }

        let defaultEncoding = String.Encoding.isoLatin1
        return String(data: body, encoding: encoding ?? defaultEncoding)
    }
}

extension URLSession {

    /// Create a background URLSession instance that can be used in the `perform(request:...)` async function.
    ///
    /// The `perform(request:...)` async function can be used in all non-background `URLSession` instances without any
    /// extra work. However, there is a requirement to make the function works with with background `URLSession` instances.
    /// That is the `URLSession` must have a delegate of `BackgroundURLSessionDelegate` type.
    static func backgroundSession(configuration: URLSessionConfiguration) -> URLSession {
        assert(configuration.identifier != nil)
        // Pass `delegateQueue: nil` to get a serial queue, which is required to ensure thread safe access to
        // `WordPressKitSessionDelegate` instances.
        return URLSession(configuration: configuration, delegate: BackgroundURLSessionDelegate(), delegateQueue: nil)
    }

    /// Send a HTTP request and return its response as a `WordPressAPIResult` instance.
    ///
    /// ## Progress Tracking and Cancellation
    ///
    /// You can track the HTTP request's overall progress by passing a `Progress` instance to the `fulfillingProgress`
    /// parameter, which must satisify following requirements:
    /// - `totalUnitCount` must not be zero.
    /// - `completedUnitCount` must be zero.
    /// - It's used exclusivity for tracking the HTTP request overal progress: No children in its progress tree.
    /// - `cancellationHandler` must be nil. You can call `fulfillingProgress.cancel()` to cancel the ongoing HTTP request.
    ///
    ///  Upon completion, the HTTP request's progress fulfills the `fulfillingProgress`.
    ///
    /// - Parameters:
    ///   - builder: A `HTTPRequestBuilder` instance that represents an HTTP request to be sent.
    ///   - acceptableStatusCodes: HTTP status code ranges that are considered a successful response. Responses with
    ///         a status code outside of these ranges are returned as a `WordPressAPIResult.unacceptableStatusCode` instance.
    ///   - parentProgress: A `Progress` instance that will be used as the parent progress of the HTTP request's overall
    ///         progress. See the function documentation regarding requirements on this argument.
    ///   - errorType: The concret endpoint error type.
    func perform<E: LocalizedError>(
        request builder: HTTPRequestBuilder,
        acceptableStatusCodes: [ClosedRange<Int>] = [200...299],
        taskCreated: ((Int) -> Void)? = nil,
        fulfilling parentProgress: Progress? = nil,
        errorType: E.Type = E.self
    ) async -> WordPressAPIResult<HTTPAPIResponse<Data>, E> {
        if configuration.identifier != nil {
            assert(delegate is BackgroundURLSessionDelegate, "Unexpected `URLSession` delegate type. See the `backgroundSession(configuration:)`")
        }

        if let parentProgress {
            assert(parentProgress.completedUnitCount == 0 && parentProgress.totalUnitCount > 0, "Invalid parent progress")
            assert(parentProgress.cancellationHandler == nil, "The progress instance's cancellationHandler property must be nil")
        }

        return await withCheckedContinuation { continuation in
            let completion: @Sendable (Data?, URLResponse?, Error?) -> Void = { data, response, error in
                let result: WordPressAPIResult<HTTPAPIResponse<Data>, E> = Self.parseResponse(
                    data: data,
                    response: response,
                    error: error,
                    acceptableStatusCodes: acceptableStatusCodes
                )

                continuation.resume(returning: result)
            }

            let task: URLSessionTask

            do {
                task = try self.task(for: builder, completion: completion)
            } catch {
                continuation.resume(returning: .failure(.requestEncodingFailure(underlyingError: error)))
                return
            }

            task.resume()
            taskCreated?(task.taskIdentifier)

            if let parentProgress, parentProgress.totalUnitCount > parentProgress.completedUnitCount {
                let pending = parentProgress.totalUnitCount - parentProgress.completedUnitCount
                // The Jetpack/WordPress app requires task progress updates to be delievered on the main queue.
                let progressUpdator = parentProgress.update(totalUnit: pending, with: task.progress, queue: .main)

                parentProgress.cancellationHandler = { [weak task] in
                    task?.cancel()
                    progressUpdator.cancel()
                }
            }
        }
    }

    private func task(
        for builder: HTTPRequestBuilder,
        completion originalCompletion: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) throws -> URLSessionTask {
        var request = try builder.build(encodeBody: false)

        // This additional `callCompletionFromDelegate` is added to unit test `BackgroundURLSessionDelegate`.
        // Background `URLSession` doesn't work on unit tests, we have to create a non-background `URLSession`
        // which has a `BackgroundURLSessionDelegate` delegate in order to test `BackgroundURLSessionDelegate`.
        //
        // In reality, `callCompletionFromDelegate` and `isBackgroundSession` have the same value.
        let callCompletionFromDelegate = delegate is BackgroundURLSessionDelegate
        let isBackgroundSession = configuration.identifier != nil
        let task: URLSessionTask
        let body = try builder.encodeMultipartForm(request: &request, forceWriteToFile: isBackgroundSession)
            ?? builder.encodeXMLRPC(request: &request, forceWriteToFile: isBackgroundSession)
        var completion = originalCompletion
        if let body {
            // Use special `URLSession.uploadTask` API for multipart POST requests.
            task = body.map(
                left: {
                    if callCompletionFromDelegate {
                        return uploadTask(with: request, from: $0)
                    } else {
                        return uploadTask(with: request, from: $0, completionHandler: completion)
                    }
                },
                right: { tempFileURL in
                    // Remove the temp file, which contains request body, once the HTTP request completes.
                    completion = { data, response, error in
                        try? FileManager.default.removeItem(at: tempFileURL)
                        originalCompletion(data, response, error)
                    }

                    if callCompletionFromDelegate {
                        return uploadTask(with: request, fromFile: tempFileURL)
                    } else {
                        return uploadTask(with: request, fromFile: tempFileURL, completionHandler: completion)
                    }
                }
            )
        } else {
            // Use `URLSession.dataTask` for all other request
            if callCompletionFromDelegate {
                task = dataTask(with: request)
            } else {
                task = dataTask(with: request, completionHandler: completion)
            }
        }

        if callCompletionFromDelegate {
            assert(delegate is BackgroundURLSessionDelegate, "Unexpected `URLSession` delegate type. See the `backgroundSession(configuration:)`")

            set(completion: completion, forTaskWithIdentifier: task.taskIdentifier)
        }

        return task
    }

    private static func parseResponse<E: LocalizedError>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        acceptableStatusCodes: [ClosedRange<Int>]
    ) -> WordPressAPIResult<HTTPAPIResponse<Data>, E> {
        let result: WordPressAPIResult<HTTPAPIResponse<Data>, E>

        if let error {
            if let urlError = error as? URLError {
                result = .failure(.connection(urlError))
            } else {
                result = .failure(.unknown(underlyingError: error))
            }
        } else {
            if let httpResponse = response as? HTTPURLResponse {
                if acceptableStatusCodes.contains(where: { $0 ~= httpResponse.statusCode }) {
                    result = .success(HTTPAPIResponse(response: httpResponse, body: data ?? Data()))
                } else {
                    result = .failure(.unacceptableStatusCode(response: httpResponse, body: data ?? Data()))
                }
            } else {
                result = .failure(.unparsableResponse(response: nil, body: data))
            }
        }

        return result
    }

}

extension WordPressAPIResult {

    func mapSuccess<NewSuccess, E: LocalizedError>(
        _ transform: (Success) throws -> NewSuccess
    ) -> WordPressAPIResult<NewSuccess, E> where Success == HTTPAPIResponse<Data>, Failure == WordPressAPIError<E> {
        flatMap { success in
            do {
                return try .success(transform(success))
            } catch {
                return .failure(.unparsableResponse(response: success.response, body: success.body, underlyingError: error))
            }
        }
    }

    func decodeSuccess<NewSuccess: Decodable, E: LocalizedError>(
        _ decoder: JSONDecoder = JSONDecoder(),
        type: NewSuccess.Type = NewSuccess.self
    ) -> WordPressAPIResult<NewSuccess, E> where Success == HTTPAPIResponse<Data>, Failure == WordPressAPIError<E> {
        mapSuccess {
            try decoder.decode(type, from: $0.body)
        }
    }

    func mapUnacceptableStatusCodeError<E: LocalizedError>(
        _ transform: (HTTPURLResponse, Data) throws -> E
    ) -> WordPressAPIResult<Success, E> where Failure == WordPressAPIError<E> {
        mapError { error in
            if case let .unacceptableStatusCode(response, body) = error {
                do {
                    return try WordPressAPIError<E>.endpointError(transform(response, body))
                } catch {
                    return WordPressAPIError<E>.unparsableResponse(response: response, body: body, underlyingError: error)
                }
            }
            return error
        }
    }

    func mapUnacceptableStatusCodeError<E>(
        _ decoder: JSONDecoder = JSONDecoder()
    ) -> WordPressAPIResult<Success, E> where E: LocalizedError, E: Decodable, Failure == WordPressAPIError<E> {
        mapUnacceptableStatusCodeError { _, body in
            try decoder.decode(E.self, from: body)
        }
    }

}

extension Progress {
    func update(totalUnit: Int64, with progress: Progress, queue: DispatchQueue) -> AnyCancellable {
        let start = self.completedUnitCount
        return progress.publisher(for: \.fractionCompleted, options: .new)
            .receive(on: queue)
            .sink { [weak self] fraction in
                self?.completedUnitCount = start + Int64(fraction * Double(totalUnit))
            }
    }
}

// MARK: - Background URL Session Support

private final class SessionTaskData {
    var responseBody = Data()
    var completion: ((Data?, URLResponse?, Error?) -> Void)?
}

class BackgroundURLSessionDelegate: NSObject, URLSessionDataDelegate {

    private var taskData = [Int: SessionTaskData]()

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        session.received(data, forTaskWithIdentifier: dataTask.taskIdentifier)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        session.completed(with: error, response: task.response, forTaskWithIdentifier: task.taskIdentifier)
    }

}

private extension URLSession {

    static var taskDataKey = 0

    // A map from `URLSessionTask` identifier to in-memory data of the given task.
    //
    // This property is in `URLSession` not `BackgroundURLSessionDelegate` because task id (the key) is unique within
    // the context of a `URLSession` instance. And in theory `BackgroundURLSessionDelegate` can be used by multiple
    // `URLSession` instances.
    var taskData: [Int: SessionTaskData] {
        get {
            objc_getAssociatedObject(self, &URLSession.taskDataKey) as? [Int: SessionTaskData] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &URLSession.taskDataKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func updateData(forTaskWithIdentifier taskID: Int, using closure: (SessionTaskData) -> Void) {
        let task = self.taskData[taskID] ?? SessionTaskData()
        closure(task)
        self.taskData[taskID] = task
    }

    func set(completion: @escaping (Data?, URLResponse?, Error?) -> Void, forTaskWithIdentifier taskID: Int) {
        updateData(forTaskWithIdentifier: taskID) {
            $0.completion = completion
        }
    }

    func received(_ data: Data, forTaskWithIdentifier taskID: Int) {
        updateData(forTaskWithIdentifier: taskID) { task in
            task.responseBody.append(data)
        }
    }

    func completed(with error: Error?, response: URLResponse?, forTaskWithIdentifier taskID: Int) {
        guard let task = taskData[taskID] else {
            return
        }

        if let error {
            task.completion?(nil, response, error)
        } else {
            task.completion?(task.responseBody, response, nil)
        }

        self.taskData.removeValue(forKey: taskID)
    }

}

extension URLSession {
    var debugNumberOfTaskData: Int {
        self.taskData.count
    }
}
