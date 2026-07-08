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

    // MARK: - Tests

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

        service.updateSharingButtonsForSite(
            mockID,
            sharingButtons: [RemoteSharingButton](),
            success: nil,
            failure: nil
        )

        XCTAssertTrue(api.postMethodCalled, "Method was not called")
        XCTAssertEqual(api.URLStringPassedIn, url, "Incorrect URL passed in")
    }
}
