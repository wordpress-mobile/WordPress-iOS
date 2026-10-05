import Foundation

/// Renders the template expressions in a response, the way WireMock's
/// [response templating](https://wiremock.org/docs/response-templating/) does.
///
/// This covers the expressions the fixtures use, which is a small part of what WireMock offers:
///
/// - `{{request.requestLine.baseUrl}}`, `{{request.query.name}}`, `{{request.pathSegments.[2]}}`
///   and `{{request.body}}`
/// - `{{now}}`, with the optional arguments `offset='-3 days'` and `format='yyyy-MM-dd'`
/// - `{{jsonPath request.body '$.title'}}`, `{{lookup request.query 'name'}}` and `{{capitalize value}}`
/// - `{{#assign 'name'}}value{{/assign}}`, which defines a variable later expressions can refer to
///
/// A request value that isn't there renders as nothing, as it does in WireMock. An expression this
/// type can't evaluate is an error.
struct ResponseTemplate {
    struct Failure: Error {
        let reason: String
    }

    let request: StubRequest
    let now: Date
    private var variables: [String: String] = [:]

    init(request: StubRequest, now: Date) {
        self.request = request
        self.now = now
    }

    mutating func render(_ template: String) throws(Failure) -> String {
        var output = ""
        var rest = template[...]

        while let open = rest.range(of: "{{") {
            output += rest[..<open.lowerBound]
            guard let close = rest[open.upperBound...].range(of: "}}") else {
                throw Failure(reason: "a template expression is missing its closing braces")
            }
            let expression = rest[open.upperBound..<close.lowerBound]
            rest = rest[close.upperBound...]

            var tokens = try Self.tokens(in: expression)[...]
            if tokens.first == .word("#assign") {
                guard tokens.count == 2, case .literal(let name) = tokens.last else {
                    throw Failure(reason: "#assign takes one quoted name")
                }
                guard let end = rest.range(of: "{{/assign}}") else {
                    throw Failure(reason: "#assign is missing its {{/assign}}")
                }
                variables[name] = try render(String(rest[..<end.lowerBound]))
                rest = rest[end.upperBound...]
            } else {
                output += try evaluate(&tokens).text
                guard tokens.isEmpty else {
                    throw Failure(reason: "unexpected text in {{\(expression)}}")
                }
            }
        }

        return output + rest
    }

    // MARK: - Evaluating

    private enum Value {
        case text(String)
        case queryParameters([(name: String, value: String)])

        var text: String {
            switch self {
            case .text(let text): text
            case .queryParameters: ""
            }
        }
    }

    /// Evaluates a helper call or a single value, consuming its tokens.
    private func evaluate(_ tokens: inout ArraySlice<Token>) throws(Failure) -> Value {
        guard case .word(let name) = tokens.first, Self.helpers.contains(name) else {
            return try value(&tokens)
        }
        tokens.removeFirst()

        var positional: [Value] = []
        var named: [String: String] = [:]
        while let token = tokens.first, token != .close {
            if case .word(let word) = token, word.hasSuffix("=") {
                tokens.removeFirst()
                named[String(word.dropLast())] = try value(&tokens).text
            } else if case .word(let word) = token, let equals = word.firstIndex(of: "=") {
                tokens.removeFirst()
                named[String(word[..<equals])] = try resolve(String(word[word.index(after: equals)...])).text
            } else {
                positional.append(try value(&tokens))
            }
        }

        return .text(try call(name, positional, named))
    }

    /// Evaluates one value: a quoted literal, a parenthesized helper call, or a path.
    private func value(_ tokens: inout ArraySlice<Token>) throws(Failure) -> Value {
        switch tokens.popFirst() {
        case .literal(let text):
            return .text(text)
        case .word(let path):
            return try resolve(path)
        case .open:
            let value = try evaluate(&tokens)
            guard tokens.popFirst() == .close else {
                throw Failure(reason: "a parenthesis is not closed")
            }
            return value
        case .close, nil:
            throw Failure(reason: "an expression is missing a value")
        }
    }

    private func resolve(_ path: String) throws(Failure) -> Value {
        if let variable = variables[path] {
            return .text(variable)
        }

        switch path {
        case "request.requestLine.baseUrl":
            return .text(request.baseURL)
        case "request.body":
            return .text(request.bodyString ?? "")
        case "request.query":
            return .queryParameters(request.queryParameters)
        default:
            break
        }

        if let name = path.wholeMatch(of: /request\.query\.(.+)/).map({ String($0.1) }) {
            return .text(request.queryParameters.first { $0.name == name }?.value ?? "")
        }
        if let index = path.wholeMatch(of: /request\.pathSegments\.\[(\d+)\]/).flatMap({ Int($0.1) }) {
            let segments = request.pathSegments
            return .text(segments.indices.contains(index) ? segments[index] : "")
        }
        throw Failure(reason: "unsupported template expression: \(path)")
    }

    // MARK: - Helpers

    private static let helpers: Set<String> = ["now", "jsonPath", "lookup", "capitalize"]

    private func call(_ helper: String, _ positional: [Value], _ named: [String: String]) throws(Failure) -> String {
        switch (helper, positional.count) {
        case ("now", 0):
            return try date(named)
        case ("jsonPath", 2):
            guard let path = JSONPath(positional[1].text) else {
                throw Failure(reason: "unsupported JSONPath expression: \(positional[1].text)")
            }
            let document = Data(positional[0].text.utf8)
            let json = try? JSONSerialization.jsonObject(with: document, options: .fragmentsAllowed)
            return json.flatMap { path.string(in: $0) } ?? ""
        case ("lookup", 2):
            guard case .queryParameters(let parameters) = positional[0] else {
                throw Failure(reason: "lookup only reads request.query")
            }
            return parameters.first { $0.name == positional[1].text }?.value ?? ""
        case ("capitalize", 1):
            return positional[0].text.capitalized
        default:
            throw Failure(reason: "\(helper) doesn't take \(positional.count) arguments")
        }
    }

    private func date(_ arguments: [String: String]) throws(Failure) -> String {
        if let unsupported = arguments.keys.sorted().first(where: { $0 != "offset" && $0 != "format" }) {
            throw Failure(reason: "now doesn't support the argument \(unsupported)")
        }

        var date = now
        if let offset = arguments["offset"] {
            date = try Self.date(date, offsetBy: offset)
        }

        switch arguments["format"] {
        case nil:
            return date.formatted(.iso8601)
        case "epoch":
            return String(Int64(date.timeIntervalSince1970 * 1000))
        case "unix":
            return String(Int64(date.timeIntervalSince1970))
        case let format?:
            let formatter = DateFormatter()
            formatter.calendar = Self.calendar
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = Self.calendar.timeZone
            formatter.dateFormat = format
            return formatter.string(from: date)
        }
    }

    /// Dates are computed and written in UTC, as WireMock does without a `timezone` argument.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private static let offsetUnits: [String: Calendar.Component] = [
        "seconds": .second,
        "minutes": .minute,
        "hours": .hour,
        "days": .day,
        "months": .month,
        "years": .year
    ]

    private static func date(_ date: Date, offsetBy offset: String) throws(Failure) -> Date {
        let parts = offset.split(separator: " ")
        guard
            parts.count == 2,
            let amount = Int(parts[0]),
            let unit = offsetUnits[String(parts[1])],
            let result = calendar.date(byAdding: unit, value: amount, to: date)
        else {
            throw Failure(reason: "unsupported date offset: \(offset)")
        }
        return result
    }

    // MARK: - Tokens

    private enum Token: Equatable {
        /// A path, a helper name, or a named argument (`format=name`, or `offset=` before a literal).
        case word(String)
        /// A quoted string, without its quotes.
        case literal(String)
        case open
        case close
    }

    private static func tokens(in expression: Substring) throws(Failure) -> [Token] {
        var tokens: [Token] = []
        var rest = expression

        while let character = rest.first {
            if character.isWhitespace {
                rest.removeFirst()
            } else if character == "(" {
                tokens.append(.open)
                rest.removeFirst()
            } else if character == ")" {
                tokens.append(.close)
                rest.removeFirst()
            } else if character == "'" || character == "\"" {
                rest.removeFirst()
                guard let end = rest.firstIndex(of: character) else {
                    throw Failure(reason: "a quoted value in {{\(expression)}} is not closed")
                }
                tokens.append(.literal(String(rest[..<end])))
                rest = rest[rest.index(after: end)...]
            } else {
                let word = rest.prefix { !$0.isWhitespace && !"()'\"".contains($0) }
                tokens.append(.word(String(word)))
                rest = rest[word.endIndex...]
            }
        }

        return tokens
    }
}
