import Foundation
import Testing
import WordPressAPI

@Suite("Blocking upload transport")
struct BlockingFakeUploadTransportTests {
    @Test func resumesEveryWaitingUpload() async throws {
        let transport = BlockingFakeUploadTransport()
        let tasks = (0..<4)
            .map { _ in
                Task { try await transport.upload(params: .init(filePath: "fixture"), fulfilling: Progress()) }
            }
        try await transport.waitUntilBlocked(count: 4)
        await transport.unblock()
        for task in tasks { _ = try await task.value }
        #expect(await transport.blockedCount == 0)
    }

    @Test func cancellationRemovesOnlyItsWaiter() async throws {
        let transport = BlockingFakeUploadTransport()
        let cancelled = Task {
            try await transport.upload(params: .init(filePath: "first"), fulfilling: Progress())
        }
        let other = Task {
            try await transport.upload(params: .init(filePath: "second"), fulfilling: Progress())
        }
        try await transport.waitUntilBlocked(count: 2)
        cancelled.cancel()
        await #expect(throws: CancellationError.self) { _ = try await cancelled.value }
        #expect(await transport.blockedCount == 1)
        await transport.unblock()
        _ = try await other.value
    }

    @Test func earlyAndRepeatedUnblockDoNotStrandUploads() async throws {
        let transport = BlockingFakeUploadTransport()
        await transport.unblock()
        await transport.unblock()
        _ = try await transport.upload(params: .init(filePath: "later"), fulfilling: Progress())
        #expect(await transport.blockedCount == 0)
    }

    @Test func cancellationBeforeRegistrationDoesNotStrandUpload() async {
        let transport = BlockingFakeUploadTransport()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await transport.upload(params: .init(filePath: "cancelled"), fulfilling: Progress())
        }
        await #expect(throws: CancellationError.self) { _ = try await task.value }
        #expect(await transport.blockedCount == 0)
    }

    @Test func missingUploadTimesOut() async {
        let transport = BlockingFakeUploadTransport()
        await #expect(throws: WaitTimedOut.self) {
            try await transport.waitUntilBlocked(timeout: .milliseconds(20))
        }
    }
}
