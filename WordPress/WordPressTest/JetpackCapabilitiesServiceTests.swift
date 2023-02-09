import Foundation
import XCTest

@testable import WordPress

class JetpackCapabilitiesServiceTests: CoreDataTestCase {

    /// Gives the correct siteIDs to the remote service
    func testCallServiceRemote() {
        let remoteMock = JetpackCapabilitiesServiceRemoteMock()
        let service = JetpackCapabilitiesService(coreDataStack: contextManager, capabilitiesServiceRemote: remoteMock)

        service.sync(blogs: [RemoteBlog.mock()], success: { _ in })

        XCTAssertEqual(remoteMock.forCalledWithSiteIds, [100])
    }

    /// Changes the RemoteBlog to contain the returned Jetpack Capabilities
    func testChangeRemoteBlogCapabilities() {
        let expect = expectation(description: "Adds jetpack capabilities into the RemoteBlog")

        let remoteMock = JetpackCapabilitiesServiceRemoteMock()
        let service = JetpackCapabilitiesService(coreDataStack: contextManager, capabilitiesServiceRemote: remoteMock)

        service.sync(blogs: [RemoteBlog.mock()], success: { blogs in
            XCTAssertTrue(blogs.first!.capabilities["backup"]!)
            XCTAssertTrue(blogs.first!.capabilities["scan"]!)
            expect.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
    }
}

class JetpackCapabilitiesServiceRemoteMock: JetpackCapabilitiesServiceRemote {
    var forCalledWithSiteIds: [Int] = []

    override func `for`(siteIds: [Int], success: @escaping ([String: AnyObject]) -> Void) {
        forCalledWithSiteIds = siteIds

        var capabilities: [String: AnyObject] = [:]
        siteIds.forEach { capabilities["\($0)"] = ["backup", "scan"] as AnyObject }

        success(capabilities)
    }
}

private extension RemoteBlog {
    static func mock() -> RemoteBlog {
        return RemoteBlog(jsonDictionary: ["ID": 100, "capabilities": ["foo": true]])
    }
}
