import Foundation
import Combine

public protocol UserServiceProtocol: Actor {
    var users: [DisplayUser]? { get }
    nonisolated var usersUpdates: AsyncStream<[DisplayUser]> { get }

    func fetchUsers() async throws -> [DisplayUser]

    func isCurrentUser(_ user: DisplayUser) async -> Bool

    func isCurrentUserCapableOf(_ capability: String) async -> Bool

    func setNewPassword(id: Int32, newPassword: String) async throws

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws
}

actor MockUserProvider: UserServiceProtocol {

    enum Scenario {
        case infinitLoading
        case dummyData
        case error
    }

    var scenario: Scenario

    nonisolated let usersUpdates: AsyncStream<[DisplayUser]>
    private let usersUpdatesContinuation: AsyncStream<[DisplayUser]>.Continuation

    private(set) var users: [DisplayUser]? {
        didSet {
            if let users {
                usersUpdatesContinuation.yield(users)
            }
        }
    }

    init(scenario: Scenario = .dummyData) {
        self.scenario = scenario
        (usersUpdates, usersUpdatesContinuation) = AsyncStream<[DisplayUser]>.makeStream()
    }

    func fetchUsers() async throws -> [DisplayUser] {
        switch scenario {
        case .infinitLoading:
            // Do nothing
            try await Task.sleep(for: .seconds(24 * 60 * 60))
            return []
        case .dummyData:
            let dummyDataUrl = URL(string: "https://my.api.mockaroo.com/users.json?key=067c9730")!
            let response = try await URLSession.shared.data(from: dummyDataUrl)
            let users = try JSONDecoder().decode([DisplayUser].self, from: response.0)
            self.users = users
            return users
        case .error:
            throw URLError(.timedOut)
        }
    }

    func isCurrentUser(_ user: DisplayUser) async -> Bool {
        true
    }

    func isCurrentUserCapableOf(_ capability: String) async -> Bool {
        true
    }

    func setNewPassword(id: Int32, newPassword: String) async throws {
        // Not used in Preview
    }

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
        // Not used in Preview
    }
}
