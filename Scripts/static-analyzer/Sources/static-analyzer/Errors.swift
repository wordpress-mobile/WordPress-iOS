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
