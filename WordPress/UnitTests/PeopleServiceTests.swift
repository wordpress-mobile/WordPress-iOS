import XCTest
import Nimble
import OHHTTPStubs

@testable import WordPress

class PeopleServiceTests: CoreDataTestCase {

    let siteID = 123
    var service: PeopleService!

    override func setUpWithError() throws {
        super.setUp()

        stub(condition: isHost("public-api.wordpress.com")) { request in
            NSLog("[Warning] Received an unexpected request sent to \(String(describing: request.url))")
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }

        contextManager.performAndSave { context in
            let account = WPAccount.fixture(context: context)

            let blog = Blog(context: context)
            blog.dotComID = NSNumber(value: self.siteID)
            blog.url = "https://site123.wrodpress.com"
            blog.xmlrpc = "https://site123.wrodpress.com/xmlrpc"
            blog.account = account
        }

        let blog = try XCTUnwrap(Blog.lookup(withID: siteID, in: mainContext))
        self.service = try XCTUnwrap(PeopleService(blog: blog, coreDataStack: self.contextManager))
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testLoadUsersSuccess() {
        stub(condition: isPath("/rest/v1.1/sites/\(siteID)/users")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "users": [
                        [
                            "ID": 1,
                            "nice_name": "Name",
                            "name": "username"
                        ] as [String: Any]
                    ]
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        waitUntil { done in
            self.service.loadUsersPage(
                success: { count, _ in
                    XCTAssertEqual(count, 1)
                    done()
                },
                failure: {
                    XCTFail("Unexpected failure: \($0)")
                    done()
                }
            )
        }
    }

    func testLoadUsersFailure() {
        stub(condition: isPath("/rest/v1.1/sites/\(siteID)/users")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 500, headers: nil)
        }

        waitUntil { done in
            self.service.loadUsersPage(
                success: { count, _ in
                    XCTFail("The failure block should be called instead")
                    done()
                },
                failure: { error in
                    XCTAssertTrue(error is WordPressComRestApiError)
                    done()
                }
            )
        }
    }

    func testDeleteFollowerSuccess() throws {
        // Load and save followers
        stub(condition: isPath("/rest/v1.1/sites/\(siteID)/follows")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "users": [
                        [
                            "ID": 1,
                            "nice_name": "Nice Name",
                            "name": "name"
                        ] as [String: Any]
                    ]
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        waitUntil { done in
            self.service.loadFollowersPage(success: { _, _ in done() }, failure: { _ in done() })
        }

        // Verify if the loaded followers are stored in the database
        let request = NSFetchRequest<ManagedPerson>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@", NSNumber(value: siteID), NSNumber(value: 1))
        try XCTAssertEqual(mainContext.count(for: request), 1)
        let follower = try XCTUnwrap(mainContext.fetch(request).first)
        XCTAssertEqual(follower.userID, 1)

        // Make API call to delete the loaded follower
        stub(condition: isPath("/rest/v1.1/sites/\(siteID)/followers/\(follower.userID)/delete")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "users": [
                        [
                            "ID": 1,
                            "nice_name": "Name",
                            "name": "username"
                        ] as [String: Any]
                    ]
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        waitUntil { done in
            self.service.deleteFollower(
                Follower(managedPerson: follower),
                success: {
                    done()
                },
                failure: {
                    XCTFail("Unexpected failure: \($0)")
                    done()
                }
            )
        }

        // Verify the follower is deleted
        try XCTAssertEqual(mainContext.count(for: request), 0)
    }

    func testDeleteFollowerFailure() throws {
        // Load and save followers
        stub(condition: isPath("/rest/v1.1/sites/\(siteID)/follows")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "users": [
                        [
                            "ID": 1,
                            "nice_name": "Nice Name",
                            "name": "name"
                        ] as [String: Any]
                    ]
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        waitUntil { done in
            self.service.loadFollowersPage(success: { _, _ in done() }, failure: { _ in done() })
        }

        // Verify if the loaded followers are stored in the database
        let request = NSFetchRequest<ManagedPerson>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@", NSNumber(value: siteID), NSNumber(value: 1))
        try XCTAssertEqual(mainContext.count(for: request), 1)
        let follower = try XCTUnwrap(mainContext.fetch(request).first)
        XCTAssertEqual(follower.userID, 1)

        // Make API call to delete the loaded follower
        stub(condition: isPath("/rest/v1.1/sites/\(siteID)/followers/\(follower.userID)/delete")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 500, headers: nil)
        }

        waitUntil { done in
            self.service.deleteFollower(
                Follower(managedPerson: follower),
                success: {
                    XCTFail("The failure block should be called instead")
                    done()
                },
                failure: { _ in
                    done()
                }
            )
        }

        // Verify the follower is not deleted from the database
        try XCTAssertEqual(mainContext.count(for: request), 1)
    }

    func testLoadFollowersFailure() {
        stub(condition: isPath("/rest/v1.1/sites/123/follows")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 500, headers: nil)
        }

        waitUntil { done in
            self.service.loadFollowersPage(
                success: { count, _ in
                    XCTFail("The failure block should be called instead")
                    done()
                },
                failure: { error in
                    XCTAssertTrue(error is WordPressComRestApiError)
                    done()
                }
            )
        }
    }

}
