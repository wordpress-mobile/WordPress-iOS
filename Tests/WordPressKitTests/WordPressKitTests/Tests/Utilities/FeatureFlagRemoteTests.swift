import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPressKit

class FeatureFlagRemoteTests: RemoteTestCase, RESTTestable {

    private let endpoint = "/wpcom/v2/mobile/feature-flags"

    func testThatRequestContainsQueryParams() throws {
        let expectation = expectation(description: "Get Remote Feature Flags Endpoint should contain query params")

        let response = try makeResponse()
        let expectedQueryParams: Set<String> = [
            "identifier",
            "platform",
            "build_number",
            "marketing_version",
            "device_id",
            "os_version",
        ]

        stub { req -> Bool in
            let containsQueryParams = self.queryParams(expectedQueryParams, containedInRequest: req)
            let matchesPath = isPath(self.endpoint)(req)
            let matchesURL = containsQueryParams && matchesPath
            XCTAssertTrue(matchesURL)
            return matchesURL
        } response: { request in
            return response
        }

        FeatureFlagRemote(wordPressComRestApi: getRestApi()).getRemoteFeatureFlags(forDeviceId: "Test") { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThatResponsesAreHandledCorrectly() throws {
        let flags = [
            FeatureFlag(title: UUID().uuidString, value: true),
            FeatureFlag(title: UUID().uuidString, value: false)
        ].sorted()

        let data = try JSONEncoder().encode(flags.dictionaryValue)
        stubRemoteResponse(endpoint, data: data, contentType: .ApplicationJSON)

        let expectation = XCTestExpectation()

        FeatureFlagRemote(wordPressComRestApi: getRestApi()).getRemoteFeatureFlags(forDeviceId: "Test") { result in
            let list = try! result.get()
            XCTAssertEqual(2, list.count)
            XCTAssertEqual(flags.first!, list.first!)
            XCTAssertEqual(flags.last!, list.last!)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThatEmptyResponsesAreHandledCorrectly() throws {

        let data = try JSONEncoder().encode(FeatureFlagList().dictionaryValue)
        stubRemoteResponse(endpoint, data: data, contentType: .ApplicationJSON)

        let expectation = XCTestExpectation()

        FeatureFlagRemote(wordPressComRestApi: getRestApi()).getRemoteFeatureFlags(forDeviceId: "Test") { result in
            XCTAssertEqual(0, try! result.get().count)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThatMalformedResponsesReturnEmptyArray() throws {
        let data = try toJSON(object: ["Invalid"])
        stubRemoteResponse(endpoint, data: data, contentType: .ApplicationJSON)

        let expectation = XCTestExpectation()

        FeatureFlagRemote(wordPressComRestApi: getRestApi()).getRemoteFeatureFlags(forDeviceId: "Test") { result in
            switch result {
                case .success: XCTFail()
                case .failure: expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThatRequestErrorReturnsFailureResponse() {
        stubRemoteResponse(endpoint, data: Data(), contentType: .NoContentType, status: 400)

        let expectation = XCTestExpectation()

        FeatureFlagRemote(wordPressComRestApi: getRestApi()).getRemoteFeatureFlags(forDeviceId: "Test") { result in
            if case .success = result {
                XCTFail()
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    private func toJSON<T: Codable>(object: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(object)
    }

    private func makeResponse() throws -> HTTPStubsResponse {
        return try XCTUnwrap({
            let flags = [
                FeatureFlag(title: UUID().uuidString, value: true),
                FeatureFlag(title: UUID().uuidString, value: false)
            ]
            guard let data = try? JSONEncoder().encode(flags.dictionaryValue) else {
                return nil
            }
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [:])
        }())
    }
}
