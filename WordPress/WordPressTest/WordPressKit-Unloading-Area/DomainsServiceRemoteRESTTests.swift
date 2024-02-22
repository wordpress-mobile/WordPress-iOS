import OHHTTPStubs
import WordPress
import XCTest

class DomainsServiceRemoteRESTTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let siteID = 12345

    let domainServiceAllDomainsMockFilename     = "domain-service-all-domain-types.json"
    let domainServiceAuthFailureMockFilename    = "site-export-auth-failure.json"
    let domainServiceBadJsonFailureMockFilename = "domain-service-bad-json.json"
    let domainServiceEmptyResponseMockFilename  = "domain-service-empty.json"
    let domainServiceSupportedStatesSuccess     = "supported-states-success.json"
    let domainServiceSupportedStatesEmpty       = "supported-states-empty.json"
    let validateDomainContactInformationFail    = "validate-domain-contact-information-response-fail.json"
    let validateDomainContactInformationSuccess = "validate-domain-contact-information-response-success.json"
    let getDomainContactInformationSuccess      = "domain-contact-information-response-success.json"
    let domainServiceInvalidQuery               = "domain-service-invalid-query.json"
    let allDomainsMockFilename                  = "get-all-domains-response.json"

    // MARK: - Properties

    var domainsEndpoint: String { return "sites/\(siteID)/domains" }

    var allDomainsEndpoint: String { return "/rest/v1.1/all-domains" }

    var remote: DomainsServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = DomainsServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - Delete Site Tests

    func testGetDomainsSucceeds() {
        let expect = expectation(description: "Get domains success")

        stubRemoteResponse(domainsEndpoint, filename: domainServiceAllDomainsMockFilename, contentType: .ApplicationJSON)
        remote.getDomainsForSite(siteID, success: { domains in
            XCTAssertNotNil(domains, "Domains array should not be nil.")
            XCTAssertEqual(domains.count, 4, "There should be four domains returned.")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetDomainsWithEmptyResponseSucceeds() {
        let expect = expectation(description: "Get domains with empty response success")

        stubRemoteResponse(domainsEndpoint, filename: domainServiceEmptyResponseMockFilename, contentType: .ApplicationJSON)
        remote.getDomainsForSite(siteID, success: { domains in
            XCTAssertNotNil(domains, "Domains array should not be nil.")
            XCTAssertEqual(domains.count, 0, "There should be zero domains returned.")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetDomainsWithServerErrorFails() {
        let expect = expectation(description: "Get domains server error failure")

        stubRemoteResponse(domainsEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getDomainsForSite(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetDomainsWithBadAuthFails() {
        let expect = expectation(description: "Get domains with bad auth failure")

        stubRemoteResponse(domainsEndpoint, filename: domainServiceAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getDomainsForSite(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetDomainsWithBadJsonFails() {
        let expect = expectation(description: "Get domains with invalid json response failure")

        stubRemoteResponse(domainsEndpoint, filename: domainServiceBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getDomainsForSite(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetStatesSuccess() {
        let expect = expectation(description: "Get states for coutry code")
        let countryCode = "US"
        stubRemoteResponse("domains/supported-states/" + countryCode,
                           filename: domainServiceSupportedStatesSuccess,
                           contentType: .ApplicationJSON,
                           status: 200)

        remote.getStates(for: countryCode,
                         success: { (stateList) in
            XCTAssert(stateList.count == 61)
            XCTAssert(stateList[0].code == "AL")
            XCTAssert(stateList[0].name == "Alabama")
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetStatesSuccessEmpty() {
        let expect = expectation(description: "Get states for coutry code")
        let countryCode = "TR"
        stubRemoteResponse("domains/supported-states/" + countryCode,
                           filename: domainServiceSupportedStatesEmpty,
                           contentType: .ApplicationJSON,
                           status: 200)

        remote.getStates(for: countryCode,
                         success: { (stateList) in
            XCTAssert(stateList.count == 0)
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidateDomainContactInformationFail() {
        let expect = expectation(description: "Validate domain contact information")
        stubRemoteResponse("me/domain-contact-information/validate",
                           filename: validateDomainContactInformationFail,
                           contentType: .ApplicationJSON,
                           status: 200)

        remote.validateDomainContactInformation(
            contactInformation: [:],
            domainNames: ["someblog.blog"], success: { (reponse) in
                XCTAssert(!reponse.success)
                XCTAssert(reponse.messages!.phone![0] == "Enter a valid country code followed by a dot (for example +1.6285550199).")
                XCTAssert(reponse.messages!.postalCode![0] == "This field is required.")
                XCTAssert(reponse.messages!.email![0] == "The 'Email' field does not appear to be valid.")
                expect.fulfill()
            }) { (_) in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidateDomainContactInformationSuccess() {
        let expect = expectation(description: "Validate domain contact information")
        stubRemoteResponse("me/domain-contact-information/validate",
                           filename: validateDomainContactInformationSuccess,
                           contentType: .ApplicationJSON,
                           status: 200)

        remote.validateDomainContactInformation(
            contactInformation: [:],
            domainNames: ["someblog.blog"], success: { (reponse) in
                XCTAssert(reponse.success)
                expect.fulfill()
            }) { (_) in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetDomainContactInformationSuccess() {
        let expect = expectation(description: "Validate domain contact information")
        stubRemoteResponse("me/domain-contact-information",
                           filename: getDomainContactInformationSuccess,
                           contentType: .ApplicationJSON,
                           status: 200)
        remote.getDomainContactInformation(
            success: { (reponse) in
                XCTAssert(reponse.email == "pinar@yahoo.com")
                XCTAssert(reponse.firstName == "Pinar")
                XCTAssert(reponse.lastName == nil)
                XCTAssert(reponse.postalCode == "12345")
                expect.fulfill()
            }) { (_) in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetDomainsWithInvalidQuery() {
        let expect = expectation(description: "Get domains with invalid query")

        stubRemoteResponse(domainsEndpoint, filename: domainServiceInvalidQuery, contentType: .ApplicationJSON, status: 400)
        remote.getDomainsForSite(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.invalidQuery.rawValue, "The error code should be 10 - invalid_query")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Get All Domains Tests

    func testAllDomainsEndpointParamsEncodingSucceds() throws {
        // Given
        let encoder = JSONEncoder()
        var params = DomainsServiceRemote.AllDomainsEndpointParams()
        params.locale = "en"
        params.noWPCOM = true
        params.resolveStatus = false

        // When
        let data = try encoder.encode(params)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        // Then
        let expectedValue = [
            "resolve_status": "false",
            "no_wpcom": "true",
            "locale": "en"
        ]
        XCTAssertEqual(json, expectedValue)
    }

    func testAllDomainsEndpointParamsEncodingFails() throws {
        // Given
        let encoder = JSONEncoder()
        var params = DomainsServiceRemote.AllDomainsEndpointParams()
        params.locale = "en"
        params.resolveStatus = true

        // When
        let data = try encoder.encode(params)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        // Then
        let expectedValue = [
            "resolve_status": "false",
            "no_wpcom": "true",
            "locale": "en"
        ]
        XCTAssertNotEqual(json, expectedValue)
    }

    func testAllDomainsEndpointSucceeds() {
        let expect = expectation(description: "Get All Domains Succeeds")
        let expectedPath = allDomainsEndpoint
        let expectedQueryParams = [
            "resolve_status": "true",
            "no_wpcom": "true",
            "locale": "en"
        ]

        stub { req -> Bool in
            let containsQueryParams = containsQueryParams(expectedQueryParams)(req)
            let matchesPath = isPath(expectedPath)(req)
            let matchesURL = containsQueryParams && matchesPath
            XCTAssertTrue(matchesURL)
            return matchesURL
        } response: { request in
            let path = OHPathForFile(self.allDomainsMockFilename, type(of: self))!
            return fixture(filePath: path, status: 200, headers: nil)
        }

        var params = DomainsServiceRemote.AllDomainsEndpointParams()
        params.noWPCOM = true
        params.resolveStatus = true
        params.locale = "en"
        remote.fetchAllDomains(params: params) { result in
            switch result {
            case .success(let domains):
                let expectedCount = 10
                XCTAssertEqual(domains.count, expectedCount, "There should be \(expectedCount) domains returned.")
            case .failure:
                XCTFail("Get All Domains request failed")
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)
    }
}
