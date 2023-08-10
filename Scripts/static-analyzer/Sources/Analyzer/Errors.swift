import IndexStoreDB

public enum AnalyzerError: Error, CustomStringConvertible {
    case symbolResolution(name: String, candidates: [Symbol])

    public var description: String {
        switch self {
        case let .symbolResolution(name, candidates):
            let reason: String
            if candidates.isEmpty {
                reason = "No candidate found"
            } else {
                reason = "\(candidates.count) candidates found:\n"
                    + candidates.map {
                        "  - \($0.name). USR: \($0.usr)"
                    }.joined(separator: "\n")
            }

            return "Failed to resolve symbol from '\(name)'. \(reason)"
        }
    }
}

enum SourceKitResponseError: Error {
    case missing(key: String)
    case unexpectedType(key: String)
}

struct AnyError: Error, CustomStringConvertible {
    var message: String

    init(message: String, file: StaticString = #file, line: Int = #line) {
        self.message = [message, "This error is reported from \(file):\(line)"].joined(separator: "\n")
    }

    var description: String {
        message
    }
}
