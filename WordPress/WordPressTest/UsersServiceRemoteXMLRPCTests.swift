@testable import WordPress
import wpxmlrpc

class UsersServiceRemoteXMLRPCTests: RemoteTestCase, XMLRPCTestable {

    // MARK: - Constants

    let fetchProfileSuccessMockFilename = "xmlrpc-response-getprofile.xml"
    let fetchProfileMissingDataMockFilename = "xmlrpc-response-valid-but-unexpected-dictionary.xml"

    // MARK: - Properties

    var remote: Any?

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = UsersServiceRemoteXMLRPC(api: getXmlRpcApi(), username: XMLRPCTestableConstants.xmlRpcUserName, password: XMLRPCTestableConstants.xmlRpcPassword)
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - Tests


    func testFetchProfileSucceeds() {
        let expect = expectation(description: "Get user profile")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: fetchProfileSuccessMockFilename, contentType: .XML)

        if let remoteInstance = remote as? UsersServiceRemoteXMLRPC {
            remoteInstance.fetchProfile({ (remoteProfile) in
                XCTAssertEqual(remoteProfile.bio, "", "Bios should be equal.")
                XCTAssertEqual(remoteProfile.displayName, "Test", "Display name should be equal.")
                XCTAssertEqual(remoteProfile.email, "user@example.com", "Email should be equal.")
                XCTAssertEqual(remoteProfile.firstName, "", "First nameshould be equal.")
                XCTAssertEqual(remoteProfile.lastName, "", "Last name should be equal.")
                XCTAssertEqual(remoteProfile.nicename, "tester", "Nicename should be equal.")
                XCTAssertEqual(remoteProfile.nickname, "tester", "Nickname should be equal.")
                XCTAssertEqual(remoteProfile.url, "", "URL should be equal.")
                XCTAssertEqual(remoteProfile.userID, 1, "User ID should be equal.")
                XCTAssertEqual(remoteProfile.username, "test", "Username should be equal.")

                expect.fulfill()

            }, failure: { (error) in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            })
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }


    func testFetchProfileDoesNotCrashWhenReceivingMissingData() {
        let expect = expectation(description: "Get user profile")

        stubRemoteResponse(XMLRPCTestableConstants.xmlRpcUrl, filename: fetchProfileMissingDataMockFilename, contentType: .XML)

        if let remoteInstance = remote as? UsersServiceRemoteXMLRPC {
            remoteInstance.fetchProfile({ (remoteProfile) in
                XCTAssertEqual(remoteProfile.bio, "", "Bios should be equal.")
                XCTAssertEqual(remoteProfile.displayName, "", "Display name should be equal.")
                XCTAssertEqual(remoteProfile.email, "", "Email should be equal.")
                XCTAssertEqual(remoteProfile.firstName, "", "First nameshould be equal.")
                XCTAssertEqual(remoteProfile.lastName, "", "Last name should be equal.")
                XCTAssertEqual(remoteProfile.nicename, "", "Nicename should be equal.")
                XCTAssertEqual(remoteProfile.nickname, "", "Nickname should be equal.")
                XCTAssertEqual(remoteProfile.url, "", "URL should be equal.")
                XCTAssertEqual(remoteProfile.userID, 0, "User ID should be equal.")
                XCTAssertEqual(remoteProfile.username, "", "Username should be equal.")

                expect.fulfill()

            }, failure: { (error) in
                XCTFail("This callback shouldn't get called")
                expect.fulfill()
            })
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
