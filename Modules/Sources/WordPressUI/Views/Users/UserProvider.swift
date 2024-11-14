import Foundation

public protocol UserDataProvider {

    typealias CachedUserListCallback = ([WordPressUI.DisplayUser]) async -> Void

    func fetchCurrentUserCan(_ capability: String) async throws -> Bool
    func fetchUsers(cachedResults: CachedUserListCallback?) async throws -> [WordPressUI.DisplayUser]

    func invalidateCaches() async throws
}

/// Subclass this and register it with the SwiftUI `.environmentObject` method
/// to perform user management actions.
///
/// The default implementation is set up for testing with SwiftUI Previews
open class UserManagementActionDispatcher: ObservableObject {
    public init() {}

    open func setNewPassword(id: Int32, newPassword: String) async throws {
        try await Task.sleep(for: .seconds(2))
    }

    open func deleteUser(id: Int32, reassigningPostsTo userId: Int32) async throws {
        try await Task.sleep(for: .seconds(2))
    }
}

package struct MockUserProvider: UserDataProvider {

    enum Scenario {
        case infinitLoading
        case dummyData
        case error
    }

    var scenario: Scenario

    init(scenario: Scenario = .dummyData) {
        self.scenario = scenario
    }

    package func fetchUsers(cachedResults: CachedUserListCallback? = nil) async throws -> [WordPressUI.DisplayUser] {
        switch scenario {
        case .infinitLoading:
            try await Task.sleep(for: .seconds(1 * 24 * 60 * 60))
            return []
        case .dummyData:
            let dummyDataUrl = URL(string: "https://my.api.mockaroo.com/users.json?key=067c9730")!
            let response = try await URLSession.shared.data(from: dummyDataUrl)
            return try JSONDecoder().decode([DisplayUser].self, from: response.0)
        case .error:
            throw URLError(.timedOut)
        }
    }

    package func fetchCurrentUserCan(_ capability: String) async throws -> Bool {
        true
    }

    package func invalidateCaches() async throws {
        // Do nothing
    }
}
