import XCTest
import AutomatticTracks

@testable import WordPress

final class WPCrashLoggingDataProviderTests: XCTestCase {

    // MARK: - Testing Log Error

    func testReadingTrackUserInMainThread() throws {
        // Given
        let dataProvider = self.makeCrashLoggingDataProvider()

        // When
        let user = try XCTUnwrap(dataProvider.currentUser)

        // Then
        XCTAssertEqual(user.userID, "\(Constants.defaultAccountID)")
        XCTAssertEqual(user.username, Constants.defaultAccountUsername)
        XCTAssertEqual(user.email, Constants.defaultAccountEmail)
    }

    func testReadingTrackUserInBackgroundThread() {
        // Given
        let expectation = XCTestExpectation(description: "Should return current user")
        let dataProvider = self.makeCrashLoggingDataProvider()
        let dispatchGroup = DispatchGroup()
        let numberOfOperations = 1000

        // When
        for _ in 0..<numberOfOperations {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                defer {
                    dispatchGroup.leave()
                }
                guard let user = dataProvider.currentUser else {
                    XCTFail("Failed to unwrap `dataProvider.currentUser`")
                    return
                }
                XCTAssertEqual(user.userID, "\(Constants.defaultAccountID)")
                XCTAssertEqual(user.username, Constants.defaultAccountUsername)
                XCTAssertEqual(user.email, Constants.defaultAccountEmail)
            }
        }

        // Then
        dispatchGroup.notify(queue: .main) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    // MARK: - Helpers

    private func makeCrashLoggingDataProvider() -> WPCrashLoggingDataProvider {
        let provider = WPCrashLoggingDataProvider(coreDataStack: makeCoreDataStack())
        return provider
    }

    private func makeCoreDataStack() -> ContextManager {
        let contextManager = ContextManager.forTesting()
        let account = AccountBuilder(contextManager)
            .with(id: Constants.defaultAccountID)
            .with(email: Constants.defaultAccountEmail)
            .with(username: Constants.defaultAccountUsername)
            .build()
        UserSettings.defaultDotComUUID = account.uuid
        return contextManager
    }

    // MARK: - Constants

    private enum Constants {
        static let defaultAccountID: Int64 = 123
        static let defaultAccountEmail: String = "foo@automattic.com"
        static let defaultAccountUsername: String = "foobar"
    }
}
