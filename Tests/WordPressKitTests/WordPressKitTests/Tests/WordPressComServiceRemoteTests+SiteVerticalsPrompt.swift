import XCTest
@testable import WordPressKit

final class SiteCreationVerticalsPromptTests: RemoteTestCase, RESTTestable {

    func testSiteVerticalsPromptRequest_Succeeds() {
        // Given
        let endpoint = "verticals/prompt"
        let fileName = "site-verticals-prompt.json"
        stubRemoteResponse(endpoint, filename: fileName, contentType: .ApplicationJSON)

        // When
        let request = Int64(1) as SiteVerticalsPromptRequest

        // Then
        let promptExpectation = expectation(description: "Initiate site verticals prompt request")
        let remote = WordPressComServiceRemote(wordPressComRestApi: getRestApi())
        remote.retrieveVerticalsPrompt(request: request) { prompt in
            promptExpectation.fulfill()
            XCTAssertNotNil(prompt)
        }

        waitForExpectations(timeout: timeout)
    }
}
