import AutomatticEncryptedLogs
import Foundation
import Testing
@testable import WordPress

@MainActor
struct EncryptedLogUploaderTests {

    private let logFiles = [
        URL(fileURLWithPath: "/tmp/logs/today.log"),
        URL(fileURLWithPath: "/tmp/logs/yesterday.log")
    ]

    @Test func queuesEveryLogFileAndReturnsItsId() throws {
        let queued = Queue()
        let uploader = makeUploader(queued: queued)

        let ids = try uploader.uploadLogs()

        #expect(queued.logs.map(\.url) == logFiles)
        #expect(ids == queued.logs.map(\.uuid))
        #expect(Set(ids).count == logFiles.count)
    }

    @Test func uploadsNothingWhenTheUserOptedOutOfSharingLogs() throws {
        let queued = Queue()
        let uploader = makeUploader(queued: queued, hasOptedOutOfCrashLogging: true)

        let ids = try uploader.uploadLogs()

        #expect(ids.isEmpty)
        #expect(queued.logs.isEmpty)
    }

    /// A reply that refers to logs the support team will never get is worse than a reply the user sends again.
    @Test func failsWhenALogCannotBeQueued() {
        let uploader = EncryptedLogUploader(
            logFiles: { self.logFiles },
            enqueue: { _ in throw EncryptedLogUploader.Failure.loggingUnavailable },
            hasOptedOutOfCrashLogging: { false }
        )

        #expect(throws: EncryptedLogUploader.Failure.loggingUnavailable) {
            try uploader.uploadLogs()
        }
    }

    private func makeUploader(queued: Queue, hasOptedOutOfCrashLogging: Bool = false) -> EncryptedLogUploader {
        EncryptedLogUploader(
            logFiles: { self.logFiles },
            enqueue: { queued.logs.append($0) },
            hasOptedOutOfCrashLogging: { hasOptedOutOfCrashLogging }
        )
    }

    @MainActor
    private final class Queue {
        var logs: [LogFile] = []
    }
}

extension EncryptedLogUploader.Failure: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loggingUnavailable, .loggingUnavailable): true
        }
    }
}
