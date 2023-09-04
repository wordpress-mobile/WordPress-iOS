import Foundation
import XCTest
import OHHTTPStubs

@testable import WordPress

class JetpackSocialServiceTests: CoreDataTestCase {

    private let timeout: TimeInterval = 1.0
    private let blogID = 1001

    private var jetpackSocialPath: String {
        "/wpcom/v2/sites/\(blogID)/jetpack-social"
    }

    private lazy var service: JetpackSocialService = {
        .init(coreDataStack: contextManager)
    }()

    override func setUp() {
        super.setUp()

        BlogBuilder(mainContext).with(blogID: blogID).build()
        contextManager.saveContextAndWait(mainContext)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: syncSharingLimit

    // non-existing PublicizeInfo + some RemotePublicizeInfo -> insert
    func testSyncSharingLimitWithNewPublicizeInfo() throws {
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: ["share_limit": 30,
                                           "to_be_publicized_count": 15,
                                           "shared_posts_count": 15,
                                           "shares_remaining": 14] as [String: Any],
                              statusCode: 200,
                              headers: nil)
        }

        let expectation = expectation(description: "syncSharingLimit should succeed")
        service.syncSharingLimit(for: blogID) { result in
            guard case .success(let sharingLimit) = result else {
                XCTFail("syncSharingLimit unexpectedly failed")
                return expectation.fulfill()
            }

            XCTAssertNotNil(sharingLimit)
            XCTAssertEqual(sharingLimit?.remaining, 14)
            XCTAssertEqual(sharingLimit?.limit, 30)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // non-existing PublicizeInfo + nil RemotePublicizeInfo -> nothing changes
    func testSyncSharingLimitWithNilPublicizeInfo() {
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let expectation = expectation(description: "syncSharingLimit should succeed")
        service.syncSharingLimit(for: blogID) { result in
            guard case .success(let sharingLimit) = result else {
                XCTFail("syncSharingLimit unexpectedly failed")
                return expectation.fulfill()
            }

            XCTAssertNil(sharingLimit)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // pre-existing PublicizeInfo + some RemotePublicizeInfo -> update
    func testSyncSharingLimitWithNewPublicizeInfoGivenPreExistingData() throws {
        try addPreExistingPublicizeInfo()
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: ["share_limit": 30,
                                           "to_be_publicized_count": 15,
                                           "shared_posts_count": 15,
                                           "shares_remaining": 14] as [String: Any],
                              statusCode: 200,
                              headers: nil)
        }

        let expectation = expectation(description: "syncSharingLimit should succeed")
        service.syncSharingLimit(for: blogID) { result in
            guard case .success(let sharingLimit) = result else {
                XCTFail("syncSharingLimit unexpectedly failed")
                return expectation.fulfill()
            }

            // the sharing limit fields should be updated according to the newest data.
            XCTAssertNotNil(sharingLimit)
            XCTAssertEqual(sharingLimit?.remaining, 14)
            XCTAssertEqual(sharingLimit?.limit, 30)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // pre-existing PublicizeInfo + nil RemotePublicizeInfo -> delete
    func testSyncSharingLimitWithNilPublicizeInfoGivenPreExistingData() throws {
        try addPreExistingPublicizeInfo()
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let expectation = expectation(description: "syncSharingLimit should succeed")
        service.syncSharingLimit(for: blogID) { result in
            guard case .success(let sharingLimit) = result else {
                XCTFail("syncSharingLimit unexpectedly failed")
                return expectation.fulfill()
            }

            // the pre-existing sharing limit should've been deleted.
            XCTAssertNil(sharingLimit)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // non-existing blog ID + some RemotePublicizeInfo
    func testSyncSharingLimitWithNewPublicizeInfoGivenInvalidBlogID() {
        let invalidBlogID = 1002
        stub(condition: isPath("/wpcom/v2/sites/\(invalidBlogID)/jetpack-social")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let expectation = expectation(description: "syncSharingLimit should fail")
        service.syncSharingLimit(for: invalidBlogID) { result in
            guard case .failure(let error) = result,
                  case .blogNotFound(let id) = error as? JetpackSocialService.ServiceError else {
                XCTFail("Expected JetpackSocialService.ServiceError to occur")
                return expectation.fulfill()
            }

            XCTAssertEqual(id, invalidBlogID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testSyncSharingLimitRemoteFetchFailure() {
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 500, headers: nil)
        }

        let expectation = expectation(description: "syncSharingLimit should fail")
        service.syncSharingLimit(for: blogID) { result in
            guard case .failure = result else {
                XCTFail("syncSharingLimit unexpectedly succeeded")
                return expectation.fulfill()
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: syncSharingLimit Objective-C

    func testObjcSyncSharingLimitSuccess() async {
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let syncSucceeded = await withCheckedContinuation { continuation in
            service.syncSharingLimit(dotComID: NSNumber(value: blogID)) {
                continuation.resume(returning: true)
            } failure: { error in
                continuation.resume(returning: false)
            }
        }

        XCTAssertTrue(syncSucceeded)
    }

    func testObjcSyncSharingLimitNilIDFailure() async {
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 500, headers: nil)
        }

        let syncSucceeded = await withCheckedContinuation { continuation in
            service.syncSharingLimit(dotComID: NSNumber(value: blogID)) {
                continuation.resume(returning: true)
            } failure: { error in
                continuation.resume(returning: false)
            }
        }

        XCTAssertFalse(syncSucceeded)
    }

    func testObjcSyncSharingLimitRequestFailure() async {
        stub(condition: isPath(jetpackSocialPath)) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 500, headers: nil)
        }

        let syncSucceeded = await withCheckedContinuation { continuation in
            service.syncSharingLimit(dotComID: NSNumber(value: blogID)) {
                continuation.resume(returning: true)
            } failure: { error in
                continuation.resume(returning: false)
            }
        }

        XCTAssertFalse(syncSucceeded)
    }

}

// MARK: - Helpers

private extension JetpackSocialServiceTests {

    func addPreExistingPublicizeInfo() throws {
        let blog = try Blog.lookup(withID: blogID, in: mainContext)
        let info = PublicizeInfo(context: mainContext)
        info.sharesRemaining = 550
        info.shareLimit = 1000
        blog?.publicizeInfo = info
        contextManager.saveContextAndWait(mainContext)
    }

}
