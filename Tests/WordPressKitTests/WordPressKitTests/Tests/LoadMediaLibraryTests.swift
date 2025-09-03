import Foundation
import XCTest

@testable import WordPressKit

private enum Kind {
    case wpcom
    case xmlrpc
}

// This test case is for the `-[MediaServiceRemote getMediaLibraryWithPageLoad:success:failure:]` method, which is
// implemented in `MediaServiceRemoteREST` and `MediaServiceRemoteXMLRPC`. The test functions in this test case are
// created to ensure both implementation shares the same behaviour.
//
// See the `-[MediaServiceRemote getMediaLibraryWithPageLoad:success:failure:]` API doc for its expected behaviours.
class LoadMediaLibraryTests: XCTestCase {

    fileprivate var kind: Kind = .wpcom

    func testSmallLibrary() {
        let mediaLibrary = MediaLibraryTestSupport(totalMedia: 50)
        let (pageLoad, success, failure) = load(mediaLibrary: mediaLibrary, failAtPage: -1)
        XCTAssertEqual(pageLoad.count, 0)
        XCTAssertEqual(success?.count, 50)
        XCTAssertNil(failure)
    }

    func testTwoPageLibrary() {
        let mediaLibrary = MediaLibraryTestSupport(totalMedia: 120)
        let (pageLoad, success, failure) = load(mediaLibrary: mediaLibrary, failAtPage: -1)
        XCTAssertEqual(pageLoad.count, 1)
        XCTAssertEqual(success?.count, 120)
        XCTAssertNil(failure)
    }

    func testLargeLibrary() {
        let mediaLibrary = MediaLibraryTestSupport(totalMedia: 650)
        let (pageLoad, success, failure) = load(mediaLibrary: mediaLibrary, failAtPage: -1)
        XCTAssertEqual(pageLoad.count, 6)
        XCTAssertEqual(success?.count, 650)
        XCTAssertNil(failure)
    }

    func testFailure() {
        let mediaLibrary = MediaLibraryTestSupport(totalMedia: 550)
        let (pageLoad, success, failure) = load(mediaLibrary: mediaLibrary, failAtPage: 3)
        XCTAssertEqual(pageLoad.count, 2)
        XCTAssertNil(success)
        XCTAssertNotNil(failure)

        let loaded = pageLoad.map { $0?.count ?? 0 }.reduce(0, +)
        XCTAssertEqual(loaded, 200)
    }

}

private extension LoadMediaLibraryTests {

    func load(mediaLibrary: MediaLibraryTestSupport, failAtPage: Int) -> MediaLibraryResult {
        let remote: MediaServiceRemote

        switch kind {
        case .wpcom:
            remote = MediaServiceRemoteREST(wordPressComRestApi: WordPressComRestApi(), siteID: 42)
            mediaLibrary.stubREST(siteID: 42, failAtPage: failAtPage)
        case .xmlrpc:
            let rpcURL = URL(string: "https://site.com/xmlrpc")!
            remote = MediaServiceRemoteXMLRPC(api: WordPressOrgXMLRPCApi(endpoint: rpcURL), username: "user", password: "pass")
            mediaLibrary.stubRPC(endpoint: rpcURL, failAtPage: failAtPage)
        }

        return waitForLoadingMediaLibrary(using: remote)
    }

    /// Wait for the `getMediaLibrary` API call to finish, and return all the potential results.
    func waitForLoadingMediaLibrary(using remote: MediaServiceRemote) -> MediaLibraryResult {
        var result: MediaLibraryResult = ([], nil, nil)

        let finished = expectation(description: "Finish loading WordPress Media Library")
        remote.getMediaLibrary {
            result.pageLoad.append($0)
        } success: {
            result.success = $0
            finished.fulfill()
        } failure: { error in
            result.failure = error
            finished.fulfill()
        }

        wait(for: [finished], timeout: 0.5)

        return result
    }
}

/// Each tuple element contains the arguments passed to their corresponding block that's passed to the
/// `-[MediaServiceRemote getMediaLibraryWithPageLoad:success:failure:]` method.
///
/// `pageLoad` is a list of lists, because the `pageLoad` block may gets called multiple times.
///
/// - SeeAlso `-[MediaServiceRemote getMediaLibraryWithPageLoad:success:failure:]`
private typealias MediaLibraryResult = (pageLoad: [[Any]?], success: [Any]?, failure: Error?)

class LoadMediaLibraryRPCTests: LoadMediaLibraryTests {

    override func setUp() {
        kind = .xmlrpc
    }

}
