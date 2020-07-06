import Foundation
import AutomatticTracks

struct EventLoggingDataProvider: EventLoggingDataSource {

    typealias LogFilesCallback = (() -> [URL])

    /// A block that returns all existing log files
    private let fetchLogFiles: LogFilesCallback?

    /// Initialize the data provider using a block.
    ///
    /// Because the most recent log file path can change at runtime (for example; if a given session spans a day boundary the logging system may roll the
    /// log file transparently in the background) we must determine which is the most recent log file each time we access it.
    init(_ block: @escaping LogFilesCallback) {
        self.fetchLogFiles = block
    }

    /// The key used to encrypt log files
    let loggingEncryptionKey: String = ApiCredentials.encryptedLogKey()

    /// The Authorization token for the upload endpoint
    var loggingAuthenticationToken: String = ApiCredentials.secret()

    /// The previous session log will be the most recent one, because they're split by day
    var previousSessionLogPath: URL? {
        return fetchLogFiles?().first
    }

    /// The current session log will always be the most recent one
    var currentSessionLogPath: URL? {
        return fetchLogFiles?().first
    }

    static func fromDDFileLogger(_ logger: DDFileLogger) -> EventLoggingDataSource {
        EventLoggingDataProvider {
            logger.logFileManager.sortedLogFileInfos.map {
                URL(fileURLWithPath: $0.filePath)
            }
        }
    }
}
