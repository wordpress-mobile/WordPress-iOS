import Foundation
import XCTest

@testable import WordPress

/// GravatarService Unit Tests
///
class JetpackCapabilitiesServiceTests: XCTestCase {

    /// Gives the correct siteIDs to the remote service
    func testCallServiceRemote() {
        let remoteMock = JetpackCapabilitiesServiceRemoteMock()
        let service = JetpackCapabilitiesService(capabilitiesServiceRemote: remoteMock)

        service.sync(blogs: [RemoteBlog.mock()], success: { _ in })

        XCTAssertEqual(remoteMock.forCalledWithSiteIds, [100])
    }

    /// In case of a failure in remote, calls the success with the current given blogs
    func testFailureCallsSuccess() {
        let expect = expectation(description: "Calls success block")

        let remoteMock = JetpackCapabilitiesServiceRemoteMock()
        let service = JetpackCapabilitiesService(capabilitiesServiceRemote: remoteMock)
        remoteMock.fails = true

        service.sync(blogs: [RemoteBlog.mock()], success: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
    }

    /// Changes the RemoteBlog to contain the returned Jetpack Capabilities
    func testChangeRemoteBlogCapabilities() {
        let expect = expectation(description: "Adds jetpack capabilities into the RemoteBlog")

        let remoteMock = JetpackCapabilitiesServiceRemoteMock()
        let service = JetpackCapabilitiesService(capabilitiesServiceRemote: remoteMock)

        service.sync(blogs: [RemoteBlog.mock()], success: { blogs in
            XCTAssertTrue(blogs.first!.capabilities["backup"] as! Bool)
            XCTAssertTrue(blogs.first!.capabilities["scan"] as! Bool)
            expect.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
    }
}

class JetpackCapabilitiesServiceRemoteMock: JetpackCapabilitiesServiceRemote {
    var forCalledWithSiteIds: [Int] = []
    var fails = false

    override func `for`(siteIds: [Int], success: @escaping ([String: AnyObject]) -> Void, failure: @escaping () -> Void) {
        forCalledWithSiteIds = siteIds

        if fails {
            failure()
        } else {
            var capabilities: [String: AnyObject] = [:]
            siteIds.forEach { capabilities["\($0)"] = ["backup", "scan"] as AnyObject }

            success(capabilities)
        }
    }
}

private extension RemoteBlog {
    static func mock() -> RemoteBlog {
        return RemoteBlog(jsonDictionary: ["ID": 100, "capabilities": ["foo": true]])
    }
}
