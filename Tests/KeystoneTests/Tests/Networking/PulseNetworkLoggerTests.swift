import Combine
import Foundation
import Pulse
import Support
import Testing
@testable import WordPress

@Suite(.serialized)
struct PulseNetworkLoggerTests {
    @Test
    func storeRequestRedactsSensitiveHeadersBeforeStoring() throws {
        let promptKeys = [
            "pulse-disable-settings-prompts",
            "pulse-disable-support-prompts",
            "pulse-disable-report-issue-prompts"
        ]
        let promptValues = promptKeys.map { UserDefaults.standard.object(forKey: $0) }
        let wasExtensiveLoggingEnabled = ExtensiveLogging.enabled
        ExtensiveLogging.enabled = true
        defer {
            ExtensiveLogging.enabled = wasExtensiveLoggingEnabled
            for (key, value) in zip(promptKeys, promptValues) {
                if let value {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }

        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let store = try LoggerStore(storeURL: storeURL, options: [.create, .inMemory])
        let logger = PulseNetworkLogger.forTesting(store: store)
        let url = URL(string: "https://example.com/wp-json/wp/v2/settings")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "authorization": "Basic secret",
            "COOKIE": "session=secret",
            "Set-Cookie": "response-cookie-in-request",
            "x-WP-nonce": "request-nonce",
            "X-Request-ID": "request-id"
        ]
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "AUTHORIZATION": "response-authorization",
                "Cookie": "response-cookie",
                "set-cookie": "session=secret",
                "x-wp-nonce": "nonce",
                "X-Response-ID": "response-id"
            ]
        )!

        var receivedEvent: LoggerStore.Event.NetworkTaskCompleted?
        let events = store.events.sink { event in
            guard case let .networkTaskCompleted(event) = event else { return }
            receivedEvent = event
        }

        logger.storeRequest(
            request,
            response: response,
            error: nil,
            data: nil
        )

        withExtendedLifetime(events) {}
        let storedEvent = try #require(receivedEvent)

        #expect(storedEvent.originalRequest.headers?.value(forHTTPHeaderField: "Authorization") == "<private>")
        #expect(storedEvent.originalRequest.headers?.value(forHTTPHeaderField: "Cookie") == "<private>")
        #expect(storedEvent.originalRequest.headers?.value(forHTTPHeaderField: "Set-Cookie") == "<private>")
        #expect(storedEvent.originalRequest.headers?.value(forHTTPHeaderField: "X-WP-Nonce") == "<private>")
        #expect(storedEvent.originalRequest.headers?.value(forHTTPHeaderField: "X-Request-ID") == "request-id")
        #expect(storedEvent.response?.headers?.value(forHTTPHeaderField: "Authorization") == "<private>")
        #expect(storedEvent.response?.headers?.value(forHTTPHeaderField: "Cookie") == "<private>")
        #expect(storedEvent.response?.headers?.value(forHTTPHeaderField: "Set-Cookie") == "<private>")
        #expect(storedEvent.response?.headers?.value(forHTTPHeaderField: "X-WP-Nonce") == "<private>")
        #expect(storedEvent.response?.headers?.value(forHTTPHeaderField: "X-Response-ID") == "response-id")
    }

    @Test
    func storeRequestIgnoresRequestsWhenExtensiveLoggingIsDisabled() throws {
        let promptKeys = [
            "pulse-disable-settings-prompts",
            "pulse-disable-support-prompts",
            "pulse-disable-report-issue-prompts"
        ]
        let promptValues = promptKeys.map { UserDefaults.standard.object(forKey: $0) }
        let wasExtensiveLoggingEnabled = ExtensiveLogging.enabled
        ExtensiveLogging.enabled = false
        defer {
            ExtensiveLogging.enabled = wasExtensiveLoggingEnabled
            for (key, value) in zip(promptKeys, promptValues) {
                if let value {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }

        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let store = try LoggerStore(storeURL: storeURL, options: [.create, .inMemory])
        let logger = PulseNetworkLogger.forTesting(store: store)
        var receivedEvent: LoggerStore.Event.NetworkTaskCompleted?
        let events = store.events.sink { event in
            guard case let .networkTaskCompleted(event) = event else { return }
            receivedEvent = event
        }

        logger.storeRequest(
            URLRequest(url: URL(string: "https://example.com")!),
            response: nil,
            error: nil,
            data: nil
        )

        withExtendedLifetime(events) {}
        #expect(receivedEvent == nil)
    }

    @Test
    func existingInstanceChecksExtensiveLoggingForEveryNativeCallback() throws {
        let promptKeys = [
            "pulse-disable-settings-prompts",
            "pulse-disable-support-prompts",
            "pulse-disable-report-issue-prompts"
        ]
        let promptValues = promptKeys.map { UserDefaults.standard.object(forKey: $0) }
        let wasExtensiveLoggingEnabled = ExtensiveLogging.enabled
        ExtensiveLogging.enabled = false
        defer {
            ExtensiveLogging.enabled = wasExtensiveLoggingEnabled
            for (key, value) in zip(promptKeys, promptValues) {
                if let value {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }

        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let store = try LoggerStore(storeURL: storeURL, options: [.create, .inMemory])
        let logger = PulseNetworkLogger.forTesting(store: store)
        let session = URLSession(configuration: .ephemeral)
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)
        request.setValue("Basic secret", forHTTPHeaderField: "authorization")
        var createdRequests: [LoggerStore.Event.NetworkTaskCreated] = []
        var completedRequestCount = 0
        let events = store.events.sink { event in
            switch event {
            case let .networkTaskCreated(event):
                createdRequests.append(event)
            case .networkTaskCompleted:
                completedRequestCount += 1
            default:
                break
            }
        }

        let disabledTask = session.dataTask(with: request)
        logger.urlSession(session, didCreateTask: disabledTask)
        #expect(createdRequests.isEmpty)

        ExtensiveLogging.enabled = true
        let enabledTask = session.dataTask(with: request)
        logger.urlSession(session, didCreateTask: enabledTask)
        #expect(createdRequests.count == 1)
        #expect(
            createdRequests.first?.originalRequest.headers?.value(forHTTPHeaderField: "Authorization") == "<private>"
        )

        ExtensiveLogging.enabled = false
        logger.urlSession(session, task: enabledTask, didCompleteWithError: nil)
        #expect(completedRequestCount == 0)

        ExtensiveLogging.enabled = true
        logger.urlSession(session, task: disabledTask, didCompleteWithError: nil)
        #expect(completedRequestCount == 1)

        withExtendedLifetime(events) {}
    }
}

private extension Dictionary where Key == String, Value == String {
    func value(forHTTPHeaderField name: String) -> String? {
        first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }
}
