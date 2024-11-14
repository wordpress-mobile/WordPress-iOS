import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
import Combine
import WordPressUI

@testable import WordPress

class UserServiceTests: XCTestCase {
    var service: UserService!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let client = try WordPressClient(api: .init(urlSession: .shared, baseUrl: .parse(input: "https://example.com"), authenticationStategy: .none), rootUrl: .parse(input: "https://example.com"))
        service = UserService(client: client)
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    func testMultipleFetchUsersTriggerOneUpdate() async throws {
        stubSuccessfullUsersFetch()

        let expectation = XCTestExpectation(description: "Updated after fetch")
        let task = Task.detached { [self] in
            for await _ in self.service.usersUpdates {
                expectation.fulfill()
            }
        }

        _ = try await [
            self.service.fetchUsers(),
            self.service.fetchUsers(),
            self.service.fetchUsers(),
            self.service.fetchUsers(),
            self.service.fetchUsers()
        ]

        await fulfillment(of: [expectation], timeout: 0.3)
        task.cancel()
    }

    func testSequentialFetchUsersTriggerOneUpdateForEachFetch() async throws {
        stubSuccessfullUsersFetch()

        let expectation = XCTestExpectation(description: "Updated after fetch")
        expectation.expectedFulfillmentCount = 5
        let task = Task.detached { [self] in
            for await _ in self.service.usersUpdates {
                expectation.fulfill()
            }
        }

        for _ in 1...expectation.expectedFulfillmentCount {
            _ = try await service.fetchUsers()
        }

        await fulfillment(of: [expectation], timeout: 0.3)

        task.cancel()
    }

    func testStreamTerminates() async throws {
        stubSuccessfullUsersFetch()

        let termination = XCTestExpectation(description: "Stream has finished")
        let task = Task.detached { [self] in
            for await _ in self.service.usersUpdates {
                // Do nothing
            }
            termination.fulfill()
        }

        _ = try await service.fetchUsers()
        _ = try await service.fetchUsers()
        _ = try await service.fetchUsers()

        // Stream should be terminated once `service` is deallocated.
        service = nil

        await fulfillment(of: [termination], timeout: 0.3)

        task.cancel()
    }

    func testDeleteUserTriggersUsersUpdate() async throws {
        stubSuccessfullUsersFetch()
        stubDeleteUser(id: 34)

        _ = try await service.fetchUsers()
        let userFetched = await service.users?.contains { $0.id == 34 } == true
        XCTAssertTrue(userFetched)

        try await service.deleteUser(id: 34, reassigningPostsTo: 1)
        let userDeleted = await service.users?.contains { $0.id == 34 } == false
        XCTAssertTrue(userDeleted)
    }

    private func stubSuccessfullUsersFetch() {
        stub(condition: isPath("/wp-json/wp/v2/users")) { _ in
            let json = #"[{"id":1,"username":"demo","name":"demo","first_name":"","last_name":"","email":"tony.li@automattic.com","url":"https:\/\/yellow-lemming-rail.jurassic.ninja","description":"","link":"https:\/\/yellow-lemming-rail.jurassic.ninja\/author\/demo\/","locale":"en_US","nickname":"demo","slug":"demo","roles":["administrator"],"registered_date":"2024-11-03T21:43:36+00:00","capabilities":{"switch_themes":true,"edit_themes":true,"activate_plugins":true,"edit_plugins":true,"edit_users":true,"edit_files":true,"manage_options":true,"moderate_comments":true,"manage_categories":true,"manage_links":true,"upload_files":true,"import":true,"unfiltered_html":true,"edit_posts":true,"edit_others_posts":true,"edit_published_posts":true,"publish_posts":true,"edit_pages":true,"read":true,"level_10":true,"level_9":true,"level_8":true,"level_7":true,"level_6":true,"level_5":true,"level_4":true,"level_3":true,"level_2":true,"level_1":true,"level_0":true,"edit_others_pages":true,"edit_published_pages":true,"publish_pages":true,"delete_pages":true,"delete_others_pages":true,"delete_published_pages":true,"delete_posts":true,"delete_others_posts":true,"delete_published_posts":true,"delete_private_posts":true,"edit_private_posts":true,"read_private_posts":true,"delete_private_pages":true,"edit_private_pages":true,"read_private_pages":true,"delete_users":true,"create_users":true,"unfiltered_upload":true,"edit_dashboard":true,"update_plugins":true,"delete_plugins":true,"install_plugins":true,"update_themes":true,"install_themes":true,"update_core":true,"list_users":true,"remove_users":true,"promote_users":true,"edit_theme_options":true,"delete_themes":true,"export":true,"administrator":true},"extra_capabilities":{"administrator":true},"avatar_urls":{"24":"https:\/\/secure.gravatar.com\/avatar\/ac05cde1cb014070c625b139e53a2899?s=24&d=mm&r=g","48":"https:\/\/secure.gravatar.com\/avatar\/ac05cde1cb014070c625b139e53a2899?s=48&d=mm&r=g","96":"https:\/\/secure.gravatar.com\/avatar\/ac05cde1cb014070c625b139e53a2899?s=96&d=mm&r=g"},"meta":{"persisted_preferences":{"core":{"isComplementaryAreaVisible":true},"core\/edit-post":{"welcomeGuide":false},"_modified":"2024-11-06T09:23:14.009Z"}},"_links":{"self":[{"href":"https:\/\/yellow-lemming-rail.jurassic.ninja\/wp-json\/wp\/v2\/users\/1"}],"collection":[{"href":"https:\/\/yellow-lemming-rail.jurassic.ninja\/wp-json\/wp\/v2\/users"}]}},{"id":34,"username":"user_1810","name":"User_2718","first_name":"","last_name":"","email":"user_5880@example.com","url":"","description":"","link":"https://yellow-lemming-rail.jurassic.ninja/author/user_1810/","locale":"en_US","nickname":"user_1810","slug":"user_1810","roles":["editor"],"registered_date":"2024-11-05T22:58:27+00:00","capabilities":{"moderate_comments":true,"manage_categories":true,"manage_links":true,"upload_files":true,"unfiltered_html":true,"edit_posts":true,"edit_others_posts":true,"edit_published_posts":true,"publish_posts":true,"edit_pages":true,"read":true,"level_7":true,"level_6":true,"level_5":true,"level_4":true,"level_3":true,"level_2":true,"level_1":true,"level_0":true,"edit_others_pages":true,"edit_published_pages":true,"publish_pages":true,"delete_pages":true,"delete_others_pages":true,"delete_published_pages":true,"delete_posts":true,"delete_others_posts":true,"delete_published_posts":true,"delete_private_posts":true,"edit_private_posts":true,"read_private_posts":true,"delete_private_pages":true,"edit_private_pages":true,"read_private_pages":true,"editor":true},"extra_capabilities":{"editor":true},"avatar_urls":{"24":"https://secure.gravatar.com/avatar/e1cf0e88fb26697102e09f3aa1fd40c7?s=24&d=mm&r=g","48":"https://secure.gravatar.com/avatar/e1cf0e88fb26697102e09f3aa1fd40c7?s=48&d=mm&r=g","96":"https://secure.gravatar.com/avatar/e1cf0e88fb26697102e09f3aa1fd40c7?s=96&d=mm&r=g"},"meta":{"persisted_preferences":[]}}]"#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }

    private func stubFailedUsersFetch() {
        stub(condition: isPath("/wp-json/wp/v2/users")) { _ in
            HTTPStubsResponse(error: URLError(.timedOut))
        }
    }

    private func stubDeleteUser(id: Int32) {
        stub(condition: isPath("/wp-json/wp/v2/users/\(id)")) { _ in
            let json = #"{"deleted":true,"previous":{"id":34,"username":"user_1810","name":"User_2718","first_name":"","last_name":"","email":"user_5880@example.com","url":"","description":"","link":"https://yellow-lemming-rail.jurassic.ninja/author/user_1810/","locale":"en_US","nickname":"user_1810","slug":"user_1810","roles":["editor"],"registered_date":"2024-11-05T22:58:27+00:00","capabilities":{"moderate_comments":true,"manage_categories":true,"manage_links":true,"upload_files":true,"unfiltered_html":true,"edit_posts":true,"edit_others_posts":true,"edit_published_posts":true,"publish_posts":true,"edit_pages":true,"read":true,"level_7":true,"level_6":true,"level_5":true,"level_4":true,"level_3":true,"level_2":true,"level_1":true,"level_0":true,"edit_others_pages":true,"edit_published_pages":true,"publish_pages":true,"delete_pages":true,"delete_others_pages":true,"delete_published_pages":true,"delete_posts":true,"delete_others_posts":true,"delete_published_posts":true,"delete_private_posts":true,"edit_private_posts":true,"read_private_posts":true,"delete_private_pages":true,"edit_private_pages":true,"read_private_pages":true,"editor":true},"extra_capabilities":{"editor":true},"avatar_urls":{"24":"https://secure.gravatar.com/avatar/e1cf0e88fb26697102e09f3aa1fd40c7?s=24&d=mm&r=g","48":"https://secure.gravatar.com/avatar/e1cf0e88fb26697102e09f3aa1fd40c7?s=48&d=mm&r=g","96":"https://secure.gravatar.com/avatar/e1cf0e88fb26697102e09f3aa1fd40c7?s=96&d=mm&r=g"},"meta":{"persisted_preferences":[]}}}"#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

    }
}
