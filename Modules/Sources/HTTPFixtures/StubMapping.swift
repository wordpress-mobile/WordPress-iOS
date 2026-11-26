#if UI_TEST_HTTP_FIXTURES
import Foundation

/// One request matcher and the response to answer with, read from a WireMock stub mapping file.
///
/// Only the parts of the [WireMock format](https://wiremock.org/docs/stubbing/) the fixtures use
/// are supported. A mapping that uses anything else fails to load instead of being read without
/// it: a matcher that was skipped would make the mapping answer requests its author excluded.
struct StubMapping: Sendable {
    /// The file the mapping was read from, relative to the `mappings` directory.
    let source: String
    let priority: Int
    let method: String?
    let url: URLMatcher
    let queryParameters: [QueryParameterMatcher]
    let bodyPatterns: [BodyMatcher]
    let scenario: Scenario?
    let response: ResponseDefinition

    /// WireMock's default priority. A lower number is tried first.
    static let defaultPriority = 5

    /// How many optional conditions the mapping places on a request. Between mappings of equal
    /// priority, the one with more conditions is tried first, so a mapping for one query doesn't
    /// lose to a catch-all for the same path.
    var specificity: Int {
        queryParameters.count + bodyPatterns.count + (scenario?.requiredState == nil ? 0 : 1)
    }

    func matches(_ request: StubRequest, scenarioStates: [String: String]) -> Bool {
        if let method, method != request.method {
            return false
        }
        if let scenario, let requiredState = scenario.requiredState {
            guard (scenarioStates[scenario.name] ?? Scenario.initialState) == requiredState else {
                return false
            }
        }
        return url.matches(request)
            && queryParameters.allSatisfy { $0.matches(request) }
            && bodyPatterns.allSatisfy { $0.matches(request) }
    }
}

// MARK: - Matchers

enum URLMatcher: Sendable {
    case any
    /// The path and query, exactly (`url`).
    case pathAndQuery(String)
    /// The path and query, as a regular expression (`urlPattern`).
    case pathAndQueryPattern(Pattern)
    /// The path, exactly (`urlPath`).
    case path(String)
    /// The path, as a regular expression (`urlPathPattern`).
    case pathPattern(Pattern)

    func matches(_ request: StubRequest) -> Bool {
        switch self {
        case .any: true
        case .pathAndQuery(let expected): request.pathAndQuery == expected
        case .pathAndQueryPattern(let pattern): pattern.matches(request.pathAndQuery)
        case .path(let expected): request.path == expected
        case .pathPattern(let pattern): pattern.matches(request.path)
        }
    }
}

struct QueryParameterMatcher: Sendable {
    enum Condition: Sendable {
        case equalTo(String)
        case matches(Pattern)
        case absent
    }

    let name: String
    let condition: Condition

    func matches(_ request: StubRequest) -> Bool {
        let values = request.queryParameters.filter { $0.name == name }.map(\.value)
        return switch condition {
        case .equalTo(let expected): values.contains(expected)
        case .matches(let pattern): values.contains(where: pattern.matches)
        case .absent: values.isEmpty
        }
    }
}

enum BodyMatcher: Sendable {
    case equalTo(String)
    case matches(Pattern)
    /// The body, as JSON serialized by `canonicalJSON`.
    case equalToJSON(Data)
    case matchesJSONPath(JSONPath)

    func matches(_ request: StubRequest) -> Bool {
        switch self {
        case .equalTo(let expected):
            request.bodyString == expected
        case .matches(let pattern):
            request.bodyString.map(pattern.matches) ?? false
        case .equalToJSON(let expected):
            request.bodyJSON.flatMap(canonicalJSON) == expected
        case .matchesJSONPath(let path):
            request.bodyJSON.map(path.matches) ?? false
        }
    }
}

/// A named state machine shared by the mappings that carry its name, which lets a sequence of
/// requests change what later requests are answered with (a new post appearing in the posts list
/// once it's been published, say).
struct Scenario: Sendable {
    static let initialState = "Started"

    let name: String
    /// The state the scenario must be in for the mapping to match.
    let requiredState: String?
    /// The state the scenario moves to once the mapping has answered a request.
    let newState: String?
}

struct ResponseDefinition: Sendable {
    let status: Int
    /// Header values may contain template expressions, like the body.
    let headers: [String: String]
    let body: String
    /// Generates the body in place of `body`, for a mapping that names the `stats-series`
    /// transformer.
    let series: StatsSeries?
    let delay: TimeInterval
}

// MARK: - Reading

extension StubMapping {
    /// - Parameters:
    ///   - data: The contents of a mapping file.
    ///   - source: The file's path, relative to the `mappings` directory.
    init(data: Data, source: String) throws(FixtureError) {
        do {
            try self.init(document: data, file: source)
        } catch let error as UnsupportedMapping {
            throw FixtureError(file: source, reason: error.reason)
        } catch {
            throw FixtureError(file: source, reason: "\(error)")
        }
    }

    private init(document: Data, file: String) throws {
        guard let json = try? JSONSerialization.jsonObject(with: document) else {
            throw UnsupportedMapping("the file is not valid JSON")
        }
        var mapping = try KeyedReader(json, at: "the mapping")
        // Identifiers and flags WireMock writes when it records a mapping. They don't affect matching.
        mapping.ignore("id", "uuid", "name", "persistent", "metadata")

        var request = try KeyedReader(try mapping.take("request"), at: "request")
        var response = try KeyedReader(try mapping.take("response"), at: "response")

        self.source = file
        self.priority = try mapping.take("priority") ?? Self.defaultPriority

        let method: String? = try request.take("method")
        self.method = method.flatMap { $0.uppercased() == "ANY" ? nil : $0.uppercased() }
        self.url = try Self.urlMatcher(from: &request)

        let queryParameters: [String: Any] = try request.take("queryParameters") ?? [:]
        self.queryParameters = try queryParameters.keys.sorted()
            .map { name in
                var condition = try KeyedReader(queryParameters[name], at: "queryParameters.\(name)")
                let matcher = QueryParameterMatcher(name: name, condition: try Self.queryCondition(from: &condition))
                try condition.finish()
                return matcher
            }

        let bodyPatterns: [Any] = try request.take("bodyPatterns") ?? []
        self.bodyPatterns = try bodyPatterns.map { pattern in
            var pattern = try KeyedReader(pattern, at: "bodyPatterns")
            let matcher = try Self.bodyMatcher(from: &pattern)
            try pattern.finish()
            return matcher
        }

        if let name: String = try mapping.take("scenarioName") {
            self.scenario = Scenario(
                name: name,
                requiredState: try mapping.take("requiredScenarioState"),
                newState: try mapping.take("newScenarioState")
            )
        } else {
            self.scenario = nil
        }

        self.response = try Self.responseDefinition(from: &response, in: document)

        try request.finish()
        try response.finish()
        try mapping.finish()
    }

    private static func urlMatcher(from request: inout KeyedReader) throws -> URLMatcher {
        var matchers: [URLMatcher] = []
        if let url: String = try request.take("url") {
            matchers.append(.pathAndQuery(url))
        }
        if let pattern: String = try request.take("urlPattern") {
            matchers.append(.pathAndQueryPattern(try Pattern(pattern)))
        }
        if let path: String = try request.take("urlPath") {
            matchers.append(.path(path))
        }
        if let pattern: String = try request.take("urlPathPattern") {
            matchers.append(.pathPattern(try Pattern(pattern)))
        }
        guard matchers.count <= 1 else {
            throw UnsupportedMapping("request has more than one of url, urlPattern, urlPath and urlPathPattern")
        }
        return matchers.first ?? .any
    }

    private static func queryCondition(from condition: inout KeyedReader) throws -> QueryParameterMatcher.Condition {
        if let expected: String = try condition.take("equalTo") {
            return .equalTo(expected)
        }
        if let pattern: String = try condition.take("matches") {
            return .matches(try Pattern(pattern))
        }
        let isAbsent: Bool? = try condition.take("absent")
        if isAbsent == true {
            return .absent
        }
        throw UnsupportedMapping("\(condition.location) needs one of equalTo, matches and absent")
    }

    private static func bodyMatcher(from pattern: inout KeyedReader) throws -> BodyMatcher {
        if let expression: String = try pattern.take("matchesJsonPath") {
            guard let path = JSONPath(expression) else {
                throw UnsupportedMapping("unsupported JSONPath expression: \(expression)")
            }
            return .matchesJSONPath(path)
        }
        if let expected: Any = try pattern.take("equalToJson") {
            // WireMock accepts the expected JSON either inline or as a string of JSON.
            let json = (expected as? String).flatMap { try? JSONSerialization.jsonObject(with: Data($0.utf8)) }
            guard let canonical = canonicalJSON(json ?? expected) else {
                throw UnsupportedMapping("equalToJson is not valid JSON")
            }
            return .equalToJSON(canonical)
        }
        if let expected: String = try pattern.take("equalTo") {
            return .equalTo(expected)
        }
        if let expression: String = try pattern.take("matches") {
            return .matches(try Pattern(expression))
        }
        throw UnsupportedMapping("\(pattern.location) needs one of equalTo, matches, equalToJson and matchesJsonPath")
    }

    private static func responseDefinition(
        from response: inout KeyedReader,
        in document: Data
    ) throws -> ResponseDefinition {
        var series: StatsSeries?
        let transformers: [String] = try response.take("transformers") ?? []
        let transformerParameters: Any? = try response.take("transformerParameters")
        for transformer in transformers {
            switch transformer {
            case "response-template":
                // Every response is rendered as a template, so naming this one changes nothing.
                break
            case "stats-series":
                do {
                    series = try StatsSeries(parameters: transformerParameters)
                } catch {
                    throw UnsupportedMapping(error.reason)
                }
            default:
                throw UnsupportedMapping("unsupported transformer: \(transformer)")
            }
        }
        if transformerParameters != nil, series == nil {
            throw UnsupportedMapping("transformerParameters are only read by the stats-series transformer")
        }

        var headers: [String: String] = [:]
        let rawHeaders: [String: Any] = try response.take("headers") ?? [:]
        for (name, value) in rawHeaders {
            guard let value = value as? String else {
                throw UnsupportedMapping("response header \(name) is not a string")
            }
            headers[name] = value
        }

        var body: String = try response.take("body") ?? ""
        let jsonBody: Any? = try response.take("jsonBody")
        if jsonBody != nil, let text = JSONText.value(at: ["response", "jsonBody"], in: document) {
            body = String(decoding: text, as: UTF8.self)
        }
        let isJSON = jsonBody != nil || series != nil
        if isJSON, !headers.keys.contains(where: { $0.caseInsensitiveCompare("Content-Type") == .orderedSame }) {
            headers["Content-Type"] = "application/json"
        }

        let delay: Int = try response.take("fixedDelayMilliseconds") ?? 0
        return ResponseDefinition(
            status: try response.take("status") ?? 200,
            headers: headers,
            body: body,
            series: series,
            delay: TimeInterval(delay) / 1000
        )
    }
}

private struct UnsupportedMapping: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

/// Reads the values of a JSON object, and reports the keys nothing read.
private struct KeyedReader {
    let location: String
    private var remaining: [String: Any]

    init(_ value: Any?, at location: String) throws {
        guard let object = value as? [String: Any] else {
            throw UnsupportedMapping("\(location) is missing or is not an object")
        }
        self.location = location
        self.remaining = object
    }

    mutating func take<Value>(_ key: String) throws -> Value? {
        guard let value = remaining.removeValue(forKey: key) else {
            return nil
        }
        guard let typed = value as? Value else {
            throw UnsupportedMapping("\(location).\(key) is not a \(Value.self)")
        }
        return typed
    }

    mutating func ignore(_ keys: String...) {
        for key in keys {
            remaining.removeValue(forKey: key)
        }
    }

    func finish() throws {
        guard remaining.isEmpty else {
            let keys = remaining.keys.sorted().joined(separator: ", ")
            throw UnsupportedMapping("\(location) has unsupported keys: \(keys)")
        }
    }
}

// MARK: - Helpers

/// A regular expression that has to match the whole of a string, which is how WireMock applies
/// every pattern in a mapping.
struct Pattern: Sendable {
    private let expression: NSRegularExpression

    fileprivate init(_ pattern: String) throws {
        do {
            expression = try NSRegularExpression(pattern: "\\A(?:\(pattern))\\z")
        } catch {
            throw UnsupportedMapping("invalid regular expression: \(pattern)")
        }
    }

    func matches(_ string: String) -> Bool {
        expression.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) != nil
    }
}

/// Serializes JSON so that equal values produce equal bytes.
func canonicalJSON(_ json: Any) -> Data? {
    try? JSONSerialization.data(
        withJSONObject: json,
        options: [.fragmentsAllowed, .sortedKeys, .withoutEscapingSlashes]
    )
}
#endif
