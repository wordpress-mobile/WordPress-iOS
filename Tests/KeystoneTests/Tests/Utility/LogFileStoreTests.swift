import CocoaLumberjack
import Foundation
import Testing
@testable import WordPress

@MainActor
struct LogFileStoreTests {

    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("LogFileStoreTests-\(UUID().uuidString)", isDirectory: true)

    @Test func listsTheFilesTheLoggerWroteNewestFirst() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileLogger = makeFileLogger()
        let log = DDLog()
        log.add(fileLogger)

        write("Yesterday", to: log)
        let first = try #require(fileLogger.currentLogFileInfo)
        await roll(fileLogger)
        // The logger names files by the millisecond, and sorts by name.
        try await Task.sleep(for: .milliseconds(10))
        write("Today", to: log)
        let second = try #require(fileLogger.currentLogFileInfo)
        #expect(first.filePath != second.filePath)

        let files = LogFileStore(fileLogger: fileLogger).logFiles()

        #expect(
            files.map(\.url.standardizedFileURL)
                == [second, first].map { URL(fileURLWithPath: $0.filePath).standardizedFileURL }
        )
        #expect(files.map(\.creationDate) == [second.creationDate, first.creationDate])
        #expect(files.allSatisfy { $0.creationDate != nil })
        #expect(files.allSatisfy { FileManager.default.fileExists(atPath: $0.url.path) })
    }

    @Test func listsNothingBeforeTheLoggerWritesAFile() {
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(LogFileStore(fileLogger: makeFileLogger()).logFiles().isEmpty)
    }

    /// Events sent now (Zendesk, non-fatal errors) attach the file the app is writing to, which is the newest one.
    @Test func eventLoggingAttachesTheNewestFile() {
        let newest = AppLogFile(url: URL(fileURLWithPath: "/tmp/logs/today.log"), creationDate: Date())
        let older = AppLogFile(
            url: URL(fileURLWithPath: "/tmp/logs/yesterday.log"),
            creationDate: Date().addingTimeInterval(-86_400)
        )
        let dataSource = EventLoggingDataProvider.from(LogFileStore { [newest, older] })

        #expect(dataSource.logFilePath(forErrorLevel: .debug, at: Date()) == newest.url)
    }

    private func makeFileLogger() -> DDFileLogger {
        DDFileLogger(logFileManager: DDLogFileManagerDefault(logsDirectory: directory.path))
    }

    private func write(_ text: String, to log: DDLog) {
        let message = DDLogMessage(
            format: text,
            formatted: text,
            level: .all,
            flag: .info,
            context: 0,
            file: #file,
            function: #function,
            line: #line,
            tag: nil,
            options: [],
            timestamp: Date()
        )
        log.log(asynchronous: false, message: message)
        log.flushLog()
    }

    private func roll(_ fileLogger: DDFileLogger) async {
        await withCheckedContinuation { continuation in
            fileLogger.rollLogFile { continuation.resume() }
        }
    }
}
