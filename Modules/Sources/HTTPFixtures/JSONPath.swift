#if UI_TEST_HTTP_FIXTURES
import Foundation

/// The two forms of JSONPath the fixtures use.
enum JSONPath: Sendable {
    /// A dotted path from the root, such as `$.options.template`.
    case path([String])
    /// An equality filter on the root, such as `$[?(@.type == 'post')]`.
    case filter(path: [String], value: String)

    init?(_ expression: String) {
        if let match = expression.wholeMatch(of: /\$((?:\.\w+)+)/) {
            self = .path(match.1.split(separator: ".").map(String.init))
        } else if let match = expression.wholeMatch(of: /\$\[\?\(@((?:\.\w+)+)\s*==\s*'([^']*)'\)\]/) {
            self = .filter(path: match.1.split(separator: ".").map(String.init), value: String(match.2))
        } else {
            return nil
        }
    }

    /// Whether the expression selects anything in `json`.
    func matches(_ json: Any) -> Bool {
        switch self {
        case .path(let path):
            return Self.value(at: path, in: json) != nil
        case .filter(let path, let expected):
            let candidates = json as? [Any] ?? [json]
            return candidates.contains { Self.value(at: path, in: $0).map(Self.string) == expected }
        }
    }

    /// The value a dotted path leads to, as the text a template renders it with.
    func string(in json: Any) -> String? {
        guard case .path(let path) = self else {
            return nil
        }
        return Self.value(at: path, in: json).map(Self.string)
    }

    private static func value(at path: [String], in json: Any) -> Any? {
        var value = json
        for key in path {
            guard let next = (value as? [String: Any])?[key], !(next is NSNull) else {
                return nil
            }
            value = next
        }
        return value
    }

    private static func string(_ value: Any) -> String {
        switch value {
        case let string as String: string
        case let number as NSNumber: number.stringValue
        default: canonicalJSON(value).map { String(decoding: $0, as: UTF8.self) } ?? ""
        }
    }
}
#endif
