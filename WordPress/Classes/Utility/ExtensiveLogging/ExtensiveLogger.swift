import Foundation
import Logging
import Support
import Pulse

struct ExtensiveLogger: LogHandler {
    let label: String
    var logLevel: Logging.Logger.Level = .info
    var metadata: Logging.Logger.Metadata = [:]

    init(label: String) {
        self.label = label
    }

    subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }

    func log(
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata: Logging.Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        guard ExtensiveLogging.enabled else { return }

        LoggerStore.shared
            .storeMessage(
                label: label,
                level: .init(level),
                message: message.description,
                metadata: self.metadata
                    .merging(metadata ?? [:], uniquingKeysWith: { _, new in new })
                    .compactMapValues(LoggerStore.MetadataValue.init),
                file: file,
                function: function,
                line: line
            )
    }
}

private extension LoggerStore.Level {
    init(_ level: Logging.Logger.Level) {
        switch level {
        case .trace: self = .trace
        case .debug: self = .debug
        case .info: self = .info
        case .notice: self = .notice
        case .warning: self = .warning
        case .error: self = .error
        case .critical: self = .critical
        }
    }
}

private extension LoggerStore.MetadataValue {
    init?(_ value: Logging.Logger.MetadataValue) {
        switch value {
        case .string(let value): self = .string(value)
        case .stringConvertible(let value): self = .stringConvertible(value)
        case .dictionary: return nil // Unsupported
        case .array: return nil // Unsupported
        }
    }
}
