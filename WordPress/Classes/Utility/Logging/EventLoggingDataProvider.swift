import BuildSettingsKit
import Foundation
import AutomatticTracks
import AutomatticEncryptedLogs

struct EventLoggingDataProvider: EventLoggingDataSource {

    typealias LogFilesCallback = (() -> [AppLogFile])

    /// A block that returns all existing log files, newest first
    private let fetchLogFiles: LogFilesCallback?

    let loggingAuthenticationToken: String
    let loggingEncryptionKey: String

    /// Initialize the data provider using a block.
    ///
    /// Because the most recent log file path can change at runtime, we must determine which is the most recent log file each time we access it.
    /// For example: if a given session spans a day boundary the logging system may roll the log file transparently in the background.
    init(
        loggingAuthenticationToken: String = BuildSettings.current.secrets.oauth.secret,
        loggingEncryptionKey: String = BuildSettings.current.secrets.encryptedLogsKey,
        _ block: @escaping LogFilesCallback
    ) {
        self.loggingAuthenticationToken = loggingAuthenticationToken
        self.loggingEncryptionKey = loggingEncryptionKey
        self.fetchLogFiles = block
    }

    /// Returns the log file that was being written to at `date`.
    ///
    /// A crash is sent on the next launch, which may have started a new log file, so the newest file isn't always the
    /// right one. The file that was current at `date` is the newest one created at or before it. If no file qualifies
    /// (for example, because creation dates are unavailable), the newest file is returned.
    func logFilePath(forErrorLevel: EventLoggingErrorType, at date: Date) -> URL? {
        Self.logFile(in: fetchLogFiles?() ?? [], at: date)?.url
    }

    static func logFile(in newestFirst: [AppLogFile], at date: Date) -> AppLogFile? {
        newestFirst.first { $0.creationDate.map { $0 <= date } ?? false } ?? newestFirst.first
    }

    static func from(_ store: LogFileStore) -> EventLoggingDataSource {
        EventLoggingDataProvider {
            store.logFiles()
        }
    }
}
