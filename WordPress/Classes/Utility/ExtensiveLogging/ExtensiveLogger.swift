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

    func log(event: LogEvent) {
        guard ExtensiveLogging.enabled else { return }

        let merged = metadata.merging(event.metadata ?? [:], uniquingKeysWith: { _, new in new })

        LoggerStore.shared
            .storeMessage(
                label: label,
                level: .init(event.level),
                message: event.message.description,
                metadata: merged.compactMapValues(LoggerStore.MetadataValue.init),
                file: event.file,
                function: event.function,
                line: event.line
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
