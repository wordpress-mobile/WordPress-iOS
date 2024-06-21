import XCTest
@testable import WordPressKit

final class SiteCreationServiceTests: RemoteTestCase, RESTTestable {

    func testSiteCreationRequest_Succeeds() {
        // Given
        let endpoint = "sites/new"
        let fileName = "site-creation-success.json"
        stubRemoteResponse(endpoint, filename: fileName, contentType: .ApplicationJSON)

        let expectedTitle = "10711c"
        let expectedUrlString = "https://10711c.wordpress.com/"

        let request = SiteCreationRequest(
            segmentIdentifier: 1,
            siteDesign: "default",
            verticalIdentifier: "p2v10",
            title: expectedTitle,
            tagline: "This is a site I like",
            siteURLString: expectedUrlString,
            isPublic: true,
            languageIdentifier: "TEST-ENGLISH",
            shouldValidate: true,
            clientIdentifier: "TEST-ID",
            clientSecret: "TEST-SECRET",
            timezoneIdentifier: TimeZone.current.identifier,
            siteCreationFlow: nil,
            findAvailableURL: false
        )

        // When, Then
        let siteCreationExpectation = expectation(description: "Initiate site creation request")
        let remote = WordPressComServiceRemote(wordPressComRestApi: getRestApi())
        remote.createWPComSite(request: request) { result in
            siteCreationExpectation.fulfill()

            switch result {
            case .success(let response):
                XCTAssertTrue(response.success)

                let site = response.createdSite
                XCTAssertEqual(site.identifier, "156355635")
                XCTAssertEqual(site.title, expectedTitle)
                XCTAssertEqual(site.urlString, expectedUrlString)
                XCTAssertEqual(site.xmlrpcString, "https://10711c.wordpress.com/xmlrpc.php")

            case .failure:
                XCTFail()
            }
        }

        waitForExpectations(timeout: timeout)
    }
}
