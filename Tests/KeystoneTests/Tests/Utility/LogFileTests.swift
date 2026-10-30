import Foundation
import Testing

@testable import WordPress

struct EventLoggingDataProviderTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func logFile(_ name: String, createdSecondsAgo seconds: TimeInterval?) -> AppLogFile {
        AppLogFile(
            url: URL(fileURLWithPath: "/logs/\(name).log"),
            creationDate: seconds.map { now.addingTimeInterval(-$0) }
        )
    }

    @Test func picksTheFileThatWasCurrentAtTheEventDate() {
        // The app crashed an hour ago, then a new log file was started on relaunch.
        let files = [logFile("relaunch", createdSecondsAgo: 60), logFile("crashed", createdSecondsAgo: 86_400)]

        let selected = EventLoggingDataProvider.logFile(in: files, at: now.addingTimeInterval(-3_600))

        #expect(selected?.url.lastPathComponent == "crashed.log")
    }

    @Test func picksTheNewestFileForTheCurrentSession() {
        let files = [logFile("current", createdSecondsAgo: 60), logFile("older", createdSecondsAgo: 86_400)]

        let selected = EventLoggingDataProvider.logFile(in: files, at: now)

        #expect(selected?.url.lastPathComponent == "current.log")
    }

    @Test func fallsBackToTheNewestFileWhenNoneQualifies() {
        let files = [logFile("newest", createdSecondsAgo: nil), logFile("older", createdSecondsAgo: 60)]

        let selected = EventLoggingDataProvider.logFile(in: files, at: now.addingTimeInterval(-3_600))

        #expect(selected?.url.lastPathComponent == "newest.log")
    }

    @Test func returnsNilWithoutLogFiles() {
        #expect(EventLoggingDataProvider.logFile(in: [], at: now) == nil)
    }
}

struct WpLogDataProviderTests {
    @Test func skipsFilesThatNoLongerExist() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let existing = directory.appendingPathComponent("existing.log")
        try Data("log".utf8).write(to: existing)
        let missing = directory.appendingPathComponent("missing.log")

        let logs = WpLogDataProvider.applicationLogs(atPaths: [missing.path, existing.path])

        #expect(logs.map(\.path.lastPathComponent) == ["existing.log"])
    }
}
