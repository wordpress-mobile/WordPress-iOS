import CocoaLumberjack
import Foundation

/// A log file the app wrote to disk.
struct AppLogFile: Hashable, Sendable {
    let url: URL
    let creationDate: Date?
}

/// Lists the app's log files, newest first.
///
/// Code that reads the log files (support screens, Zendesk, encrypted log upload, crash reports) goes through this
/// type, so it doesn't depend on the logging library that writes them.
struct LogFileStore: Sendable {
    static let shared = LogFileStore(fileLogger: WPLogger.shared().fileLogger)

    private let listFiles: @Sendable () -> [AppLogFile]

    init(listFiles: @escaping @Sendable () -> [AppLogFile]) {
        self.listFiles = listFiles
    }

    init(fileLogger: DDFileLogger) {
        self.init {
            fileLogger.logFileManager.sortedLogFileInfos.map {
                AppLogFile(url: URL(fileURLWithPath: $0.filePath), creationDate: $0.creationDate)
            }
        }
    }

    /// The log files on disk, newest first. The first one is the file the app is writing to.
    func logFiles() -> [AppLogFile] {
        listFiles()
    }
}
