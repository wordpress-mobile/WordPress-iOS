#if UI_TEST_HTTP_FIXTURES
import Foundation
import os

/// A known set of responses to answer an app's requests with, so its UI can be tested against
/// data that doesn't change.
///
/// The fixtures are [WireMock stub mappings](https://wiremock.org/docs/stubbing/): JSON files that
/// each pair a request matcher with a response, read from every `.json` file under the `mappings`
/// directory. See `StubMapping` and `ResponseTemplate` for the parts of the format that are
/// supported.
///
/// Mappings match on the path, query and body of a request, never its host, so one set answers
/// for every host the app talks to.
public final class FixtureSet: Sendable {
    /// The mappings, in the order they're tried.
    private let mappings: [StubMapping]
    private let scenarioStates = OSAllocatedUnfairLock<[String: String]>(initialState: [:])
    private let now: @Sendable () -> Date

    /// - Parameters:
    ///   - directory: The directory that contains the `mappings` directory.
    ///   - now: The clock `{{now}}` template expressions read.
    public init(directory: URL, now: @escaping @Sendable () -> Date = { Date() }) throws(FixtureError) {
        let mappingsDirectory = directory.appending(path: "mappings", directoryHint: .isDirectory)
        let files = Self.jsonFiles(in: mappingsDirectory)
        guard !files.isEmpty else {
            throw FixtureError(file: "mappings", reason: "no mappings found in \(mappingsDirectory.path())")
        }

        var mappings: [StubMapping] = []
        for file in files {
            guard let data = try? Data(contentsOf: file.url) else {
                throw FixtureError(file: file.path, reason: "the file can't be read")
            }

            let mapping = try StubMapping(data: data, source: file.path)
            try Self.validateTemplates(of: mapping)
            mappings.append(mapping)
        }

        self.mappings = mappings.sorted {
            ($0.priority, -$0.specificity, $0.source) < ($1.priority, -$1.specificity, $1.source)
        }
        self.now = now
    }

    /// The response to `request`: the one from the first mapping that matches it, or a 404 when
    /// none does.
    public func response(for request: StubRequest) -> StubResponse {
        let match = scenarioStates.withLock { states -> StubMapping? in
            guard let mapping = mappings.first(where: { $0.matches(request, scenarioStates: states) }) else {
                return nil
            }
            if let scenario = mapping.scenario, let newState = scenario.newState {
                states[scenario.name] = newState
            }
            return mapping
        }

        guard let match else {
            return .noFixture(for: request)
        }

        do throws(ResponseTemplate.Failure) {
            var template = ResponseTemplate(request: request, now: now())
            let headers = try match.response.headers.mapValues { value throws(ResponseTemplate.Failure) in
                try template.render(value)
            }
            let body =
                if let series = match.response.series {
                    series.body(for: request, now: now())
                } else {
                    try template.render(match.response.body)
                }
            return StubResponse(
                status: match.response.status,
                headers: headers,
                body: Data(body.utf8),
                delay: match.response.delay,
                source: match.source
            )
        } catch {
            return .error(status: 500, code: "invalid_fixture", message: error.reason, source: match.source)
        }
    }

    /// Renders a mapping's templates against a placeholder request, so an expression that can't be
    /// evaluated is reported when the fixtures load instead of when a test happens to request it.
    private static func validateTemplates(of mapping: StubMapping) throws(FixtureError) {
        let request = StubRequest(url: URL(string: "https://example.com/")!)
        var template = ResponseTemplate(request: request, now: Date())
        do {
            for value in mapping.response.headers.values {
                _ = try template.render(value)
            }
            _ = try template.render(mapping.response.body)
        } catch {
            throw FixtureError(file: mapping.source, reason: error.reason)
        }
    }

    /// The `.json` files under `directory`, with their paths relative to it, sorted by path.
    private static func jsonFiles(in directory: URL) -> [(path: String, url: URL)] {
        let root = directory.standardizedFileURL.path(percentEncoded: false)
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
        var files: [(path: String, url: URL)] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "json" else {
                continue
            }
            let path = url.standardizedFileURL.path(percentEncoded: false)
            files.append((path: String(path.dropFirst(root.count)), url: url))
        }
        return files.sorted { $0.path < $1.path }
    }
}
#endif
