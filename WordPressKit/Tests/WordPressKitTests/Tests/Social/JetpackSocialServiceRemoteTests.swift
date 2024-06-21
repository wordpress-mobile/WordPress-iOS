import Foundation
import XCTest
@testable import WordPressKit

class JetpackSocialServiceRemoteTests: RemoteTestCase, RESTTestable {
    let siteID = 1001
    let jetpackSocialWithPublicizeFilename = "jetpack-social-with-publicize.json"
    let jetpackSocialWithoutPublicizeFilename = "jetpack-social-no-publicize.json"
    let jetpackSocialErrorFilename = "jetpack-social-403.json"

    private var endpoint: String {
        "sites/\(siteID)/jetpack-social"
    }

    private lazy var remote: JetpackSocialServiceRemote = {
        .init(wordPressComRestApi: getRestApi())
    }()

    // MARK: - Tests

    func testPublicizeInfoReturnValueForSitesWithPublicize() {
        stubRemoteResponse(endpoint, filename: jetpackSocialWithPublicizeFilename, contentType: .ApplicationJSON)
        let expect = expectation(description: "Jetpack Social request should succeed")

        remote.fetchPublicizeInfo(for: siteID) { result in
            switch result {
            case .success(let info):
                guard let info else {
                    XCTFail("PublicizeInfo should exist")
                    return
                }

                // test parsing correctness
                XCTAssertEqual(info.shareLimit, 30)
                XCTAssertEqual(info.toBePublicizedCount, 1)
                XCTAssertEqual(info.sharedPostsCount, 15)
                XCTAssertEqual(info.sharesRemaining, 14)
                expect.fulfill()

            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
        }
        wait(for: [expect], timeout: timeout)
    }

    func testPublicizeInfoReturnValueForSitesWithoutPublicize() {
        stubRemoteResponse(endpoint, filename: jetpackSocialWithoutPublicizeFilename, contentType: .ApplicationJSON)
        let expect = expectation(description: "Jetpack Social request should succeed")

        remote.fetchPublicizeInfo(for: siteID) { result in
            switch result {
            case .success(let info):
                // for sites without publicize, the request should succeed with nil result.
                XCTAssertNil(info)
                expect.fulfill()

            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
        }
        wait(for: [expect], timeout: timeout)
    }

    func testPublicizeInfoError() {
        stubRemoteResponse(endpoint, filename: jetpackSocialErrorFilename, contentType: .ApplicationJSON, status: 403)
        let expect = expectation(description: "Jetpack Social request should fail")

        remote.fetchPublicizeInfo(for: siteID) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success result")
            case .failure:
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: timeout)
    }
}
