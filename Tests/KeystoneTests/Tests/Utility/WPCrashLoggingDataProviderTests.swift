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

    func testReadingTrackUserInBackgroundThread() async {
        let dataProvider = self.makeCrashLoggingDataProvider()
        await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 1...1000 {
                group.addTask {
                    let user = try XCTUnwrap(dataProvider.currentUser)
                    XCTAssertEqual(user.userID, "\(Constants.defaultAccountID)")
                    XCTAssertEqual(user.username, Constants.defaultAccountUsername)
                    XCTAssertEqual(user.email, Constants.defaultAccountEmail)
                }
            }
        }
    }

    // MARK: - Helpers

    private func makeCrashLoggingDataProvider() -> WPCrashLoggingDataProvider {
        let provider = WPCrashLoggingDataProvider(contextManager: makeCoreDataStack())
        return provider
    }

    private func makeCoreDataStack() -> ContextManager {
        let contextManager = ContextManager.forTesting()
        let account = AccountBuilder(contextManager.mainContext)
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
