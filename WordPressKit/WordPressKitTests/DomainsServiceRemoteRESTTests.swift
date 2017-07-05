import Foundation
import XCTest
@testable import WordPressKit

class DomainsServiceRemoteRESTTests: RemoteTestCase, RESTTestable {
    
    // MARK: - Constants
    
    let siteID = 12345
    
    let domainServiceAllDomainsMockFilename     = "domain-service-all-domain-types.json"
    let domainServiceAuthFailureMockFilename    = "site-export-auth-failure.json"
    let domainServiceBadJsonFailureMockFilename = "domain-service-bad-json.json"
    let domainServiceEmptyResponseMockFilename  = "domain-service-empty.json"
    
    // MARK: - Properties
    
    var domainsEndpoint: String { return "sites/\(siteID)/domains" }
    
    var remote: DomainsServiceRemote!
    
    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        
        remote = DomainsServiceRemote(wordPressComRestApi: restApi)
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
        }, failure: { error in
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
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testGetDomainsWithServerErrorFails() {
        let expect = expectation(description: "Get domains server error failure")
        
        stubRemoteResponse(domainsEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getDomainsForSite(siteID, success: { domains in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testDeleteSiteWithBadAuthFails() {
        let expect = expectation(description: "Get domains with bad auth failure")
        
        stubRemoteResponse(domainsEndpoint, filename: domainServiceAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getDomainsForSite(siteID, success: { domains in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteSiteWithBadJsonFails() {
        let expect = expectation(description: "Get domains with invalid json response failure")
        
        stubRemoteResponse(domainsEndpoint, filename: domainServiceBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getDomainsForSite(siteID, success: { domains in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
