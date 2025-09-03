import XCTest

@testable import WordPressKit

final class SharingServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Test Dependencies

    private lazy var api: MockWordPressComRestApi = {
        .init()
    }()

    private lazy var service: SharingServiceRemote = {
        SharingServiceRemote(wordPressComRestApi: api)
    }()

    private let publicizeServicesMockFilename = "sites-external-services.json"

    // MARK: - Tests

    func testGetPublicizeServicesV1_1() {
        let url = service.path(forEndpoint: "meta/external-services", withVersion: ._1_1)

        service.getPublicizeServices(nil, failure: nil)

        XCTAssertTrue(api.getMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")

        let typeParameter = (api.parametersPassedIn as? NSDictionary)?.value(forKey: "type") as? String
        XCTAssertEqual(typeParameter, "publicize", "Incorrect type parameter")
    }

    func testGetPublicizeServicesV2() {
        let mockID = NSNumber(value: 10)
        let expectation = expectation(description: "Publicize services v2.0 should succeed")
        let pathToStub = "sites/\(mockID)/external-services"
        let mockService = SharingServiceRemote(wordPressComRestApi: getRestApi())

        stubRemoteResponse(pathToStub, filename: publicizeServicesMockFilename, contentType: .ApplicationJSON)

        mockService.getPublicizeServices(for: mockID) { publicizeServices in
            guard let facebookService = publicizeServices.first(where: { $0.serviceID == "facebook" }) else {
                XCTFail("Expected a RemotePublicizeService to exist")
                return
            }
            XCTAssertTrue(facebookService.status.isEmpty)

            guard let twitterService = publicizeServices.first(where: { $0.serviceID == "twitter"}) else {
                XCTFail("Expected a RemotePublicizeService to exist")
                return
            }
            XCTAssertEqual(twitterService.status, "unsupported")

            expectation.fulfill()

        } failure: { _ in
            XCTFail("Failure block unexpectedly called")
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testGetKeyringServices() {
        let url = service.path(forEndpoint: "me/keyring-connections", withVersion: ._1_1)

        service.getKeyringConnections(nil, failure: nil)

        XCTAssertTrue(api.getMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")
    }

    func testGetPublicizeConnections() {
        let mockID = NSNumber(value: 10)
        let url = service.path(forEndpoint: "sites/\(mockID)/publicize-connections", withVersion: ._1_1)

        service.getPublicizeConnections(mockID, success: nil, failure: nil)

        XCTAssertTrue(api.getMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")
    }

    func testCreatePublicizeConnection() {
        let mockID = NSNumber(value: 10)
        let url = service.path(forEndpoint: "sites/\(mockID)/publicize-connections/new", withVersion: ._1_1)

        service.createPublicizeConnection(mockID,
                                          keyringConnectionID: mockID,
                                          externalUserID: nil,
                                          success: nil,
                                          failure: nil)

        XCTAssertTrue(api.postMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")
    }

    func testDeletePublicizeConnection() {
        let mockID = NSNumber(value: 10)
        let url = service.path(forEndpoint: "sites/\(mockID)/publicize-connections/\(mockID)/delete",
                               withVersion: ._1_1)

        service.deletePublicizeConnection(mockID, connectionID: mockID, success: nil, failure: nil)

        XCTAssertTrue(api.postMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")
    }

    func testGetSharingButtonsForSite() {
        let mockID = NSNumber(value: 10)
        let url = service.path(forEndpoint: "sites/\(mockID)/sharing-buttons", withVersion: ._1_1)

        service.getSharingButtonsForSite(mockID, success: nil, failure: nil)

        XCTAssertTrue(api.getMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")
    }

    func testUpdateSharingButtonsForSite() {
        let mockID = NSNumber(value: 10)
        let url = service.path(forEndpoint: "sites/\(mockID)/sharing-buttons", withVersion: ._1_1)

        service.updateSharingButtonsForSite(mockID,
                                            sharingButtons: [RemoteSharingButton](),
                                            success: nil,
                                            failure: nil)

        XCTAssertTrue(api.postMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")
    }

}
