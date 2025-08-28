import XCTest
@testable import WordPressKit

final class RemoteConfigRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: Variables

    private let endpoint = "/wpcom/v2/mobile/remote-config"

    // MARK: Tests

    func testThatResponsesAreHandledCorrectly() throws {
        // Given
        let dictionary = ["key1": "value", "key2": "value2"]
        let data = try JSONEncoder().encode(dictionary)
        stubRemoteResponse(endpoint, data: data, contentType: .ApplicationJSON)

        // When
        let expectation = XCTestExpectation()
        RemoteConfigRemote(wordPressComRestApi: getRestApi()).getRemoteConfig { result in

            // Then
            let response = try! result.get() as? [String: String]
            XCTAssertEqual(response, dictionary)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThatEmptyResponsesAreHandledCorrectly() throws {
        // Given
        let emptyDictionary: [String: String] = [:]
        let data = try JSONEncoder().encode(emptyDictionary)
        stubRemoteResponse(endpoint, data: data, contentType: .ApplicationJSON)

        // When
        let expectation = XCTestExpectation()
        RemoteConfigRemote(wordPressComRestApi: getRestApi()).getRemoteConfig { result in

            // Then
            XCTAssertEqual(0, try! result.get().count)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThatMalformedResponsesReturnEmptyArray() throws {
        // Given
        let data = try toJSON(object: ["Invalid"])
        stubRemoteResponse(endpoint, data: data, contentType: .ApplicationJSON)

        // When
        let expectation = XCTestExpectation()
        RemoteConfigRemote(wordPressComRestApi: getRestApi()).getRemoteConfig { result in

            // Then
            switch result {
                case .success: XCTFail()
                case .failure: expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThatRequestErrorReturnsFailureResponse() {
        // Given
        stubRemoteResponse(endpoint, data: Data(), contentType: .NoContentType, status: 400)

        // When
        let expectation = XCTestExpectation()
        RemoteConfigRemote(wordPressComRestApi: getRestApi()).getRemoteConfig { result in

            // Then
            if case .success = result {
                XCTFail()
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    // MARK: Helpers

    private func toJSON<T: Codable>(object: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(object)
    }

}
