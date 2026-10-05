#if DEBUG
import Foundation
import ObjectiveC
import os

/// Answers every `URLSession` request in the process from a `FixtureSet`, so nothing reaches the
/// network.
///
/// This works below the app's API clients, which is what lets one mechanism cover all of them:
/// WordPressKit, Alamofire and wordpress-rs each hand their requests to a `URLSession`.
///
/// It can't see requests that leave the process another way: the content of a `WKWebView`,
/// background sessions, WebSockets and media playback.
///
/// - warning: Compiled into debug builds only. Nothing in a release build can reroute the app's
///   requests.
public final class FixtureURLProtocol: URLProtocol, @unchecked Sendable {
    private struct Configuration: Sendable {
        let fixtures: FixtureSet
        let requestLog: RequestLog?
    }

    private static let configuration = OSAllocatedUnfairLock<Configuration?>(initialState: nil)

    /// Starts answering the process's requests from `fixtures`.
    ///
    /// Call this before the app creates its sessions: a session copies its configuration when it's
    /// created, so one that already exists keeps talking to the network.
    ///
    /// - Parameter requestLog: A file to write a `RecordedRequest` to for every request. It shows
    ///   what the app sent, and which requests the fixtures are missing.
    public static func install(fixtures: FixtureSet, requestLog: URL? = nil) {
        activate(fixtures: fixtures, requestLog: requestLog)
        _ = registration
    }

    /// Starts answering requests in sessions whose configuration lists this protocol.
    static func activate(fixtures: FixtureSet, requestLog: URL? = nil) {
        let configuration = Configuration(fixtures: fixtures, requestLog: requestLog.flatMap(RequestLog.init(url:)))
        self.configuration.withLock { $0 = configuration }
    }

    static func deactivate() {
        configuration.withLock { $0 = nil }
    }

    /// Puts the protocol in front of every session, once.
    ///
    /// `registerClass` only reaches `URLSession.shared`. A session created from a configuration
    /// reads the configuration's `protocolClasses` instead, so the protocol is also added to the
    /// two configurations sessions are created from.
    private static let registration: Void = {
        URLProtocol.registerClass(FixtureURLProtocol.self)
        addProtocol(toConfigurationReturnedBy: #selector(getter: URLSessionConfiguration.default))
        addProtocol(toConfigurationReturnedBy: #selector(getter: URLSessionConfiguration.ephemeral))
    }()

    private static func addProtocol(toConfigurationReturnedBy selector: Selector) {
        guard let method = class_getClassMethod(URLSessionConfiguration.self, selector) else {
            return
        }

        typealias Getter = @convention(c) (AnyClass, Selector) -> URLSessionConfiguration
        let original = unsafeBitCast(method_getImplementation(method), to: Getter.self)
        let replacement: @convention(block) (AnyClass) -> URLSessionConfiguration = { configurationClass in
            let configuration = original(configurationClass, selector)
            configuration.protocolClasses = [FixtureURLProtocol.self] + (configuration.protocolClasses ?? [])
            return configuration
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
    }

    // MARK: - URLProtocol

    private let isStopped = OSAllocatedUnfairLock(initialState: false)

    override public class func canInit(with request: URLRequest) -> Bool {
        guard configuration.withLock({ $0 }) != nil, let scheme = request.url?.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        guard let configuration = Self.configuration.withLock({ $0 }), let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        let stubRequest = StubRequest(method: request.httpMethod ?? "GET", url: url, body: Self.body(of: request))
        let response = configuration.fixtures.response(for: stubRequest)
        configuration.requestLog?.record(stubRequest, answeredBy: response)

        // The response is delivered after `startLoading` has returned, on the run loop of the thread
        // that called it, which is the thread the client has to be called on.
        nonisolated(unsafe) let runLoop = CFRunLoopGetCurrent()
        DispatchQueue.global()
            .asyncAfter(deadline: .now() + response.delay) {
                CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) {
                    self.deliver(response, for: url)
                }
                CFRunLoopWakeUp(runLoop)
            }
    }

    override public func stopLoading() {
        isStopped.withLock { $0 = true }
    }

    private func deliver(_ response: StubResponse, for url: URL) {
        guard !isStopped.withLock({ $0 }) else {
            return
        }
        guard
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: response.status,
                httpVersion: "HTTP/1.1",
                headerFields: response.headers
            )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    /// The most of a request body that's read to match it against the fixtures. Anything larger is
    /// an upload, which no mapping matches on.
    private static let maximumBodySize = 1024 * 1024

    /// The request's body. A request sent by an upload task, or with a stream, arrives without
    /// `httpBody`, so its body is read from the stream.
    private static func body(of request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while body.count < maximumBodySize {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else {
                break
            }
            body.append(buffer, count: count)
        }
        return body
    }
}

/// Writes a `RecordedRequest` to a file for every request, one per line.
private final class RequestLog: Sendable {
    private let file: OSAllocatedUnfairLock<FileHandle>

    init?(url: URL) {
        FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: nil)
        guard let handle = try? FileHandle(forWritingTo: url) else {
            return nil
        }
        file = OSAllocatedUnfairLock(uncheckedState: handle)
    }

    func record(_ request: StubRequest, answeredBy response: StubResponse) {
        let record = RecordedRequest(
            method: request.method,
            url: request.url,
            body: request.bodyString,
            status: response.status,
            fixture: response.source
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let json = try? encoder.encode(record) else {
            return
        }
        file.withLockUnchecked { handle in
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: json + Data("\n".utf8))
        }
    }
}
#endif
