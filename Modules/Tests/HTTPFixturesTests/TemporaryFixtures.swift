#if UI_TEST_HTTP_FIXTURES
import Foundation
import HTTPFixtures

/// Writes mappings to a temporary directory laid out the way `FixtureSet` reads them.
///
/// - Parameter mappings: The mapping files, keyed by their path under the `mappings` directory.
func makeFixtureSet(
    _ mappings: [String: String],
    now: Date = Date(timeIntervalSince1970: 1_750_000_000)
) throws -> FixtureSet {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    for (path, json) in mappings {
        let file = directory.appending(path: "mappings").appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: file)
    }
    return try FixtureSet(directory: directory, now: { now })
}

/// The text of a mapping file.
///
/// - Parameters:
///   - request: The request matcher, as JSON.
///   - response: The response, as JSON.
///   - attributes: The mapping's other keys, such as its priority, as the inside of a JSON object.
func mapping(_ request: String, response: String = #"{"status": 200}"#, attributes: String? = nil) -> String {
    let attributes = attributes.map { "\($0), " } ?? ""
    return "{\(attributes)\"request\": \(request), \"response\": \(response)}"
}

func get(_ pathAndQuery: String) -> StubRequest {
    request("GET", pathAndQuery)
}

func post(_ pathAndQuery: String, body: String? = nil) -> StubRequest {
    request("POST", pathAndQuery, body: body)
}

func request(_ method: String, _ pathAndQuery: String, body: String? = nil) -> StubRequest {
    StubRequest(
        method: method,
        url: URL(string: "https://public-api.wordpress.com\(pathAndQuery)")!,
        body: body.map { Data($0.utf8) }
    )
}

extension StubResponse {
    var text: String {
        String(decoding: body, as: UTF8.self)
    }
}
#endif
