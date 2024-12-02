import Foundation
import Combine

public protocol UserDataStore: DataStore where T == DisplayUser, Query == UserDataStoreQuery {
}

public enum UserDataStoreQuery: Equatable {
    case all
    case id(Set<DisplayUser.ID>)
    case search(String)
}

public protocol UserServiceProtocol: Actor {
    func fetchUsers() async throws

    func isCurrentUserCapableOf(_ capability: String) async -> Bool

    func setNewPassword(id: Int32, newPassword: String) async throws

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws

    func allUsers() async throws -> [DisplayUser]

    func streamSearchResult(input: String) async -> AsyncStream<Result<[DisplayUser], Error>>

    func streamAll() async -> AsyncStream<Result<[DisplayUser], Error>>
}

protocol UserDataStoreProvider: Actor {
    var userDataStore: any UserDataStore { get }
}

extension UserServiceProtocol where Self: UserDataStoreProvider {
    func allUsers() async throws -> [DisplayUser] {
        try await userDataStore.list(query: .all)
    }

    func streamSearchResult(input: String) async -> AsyncStream<Result<[DisplayUser], Error>> {
        await userDataStore.listStream(query: .search(input))
    }

    func streamAll() async -> AsyncStream<Result<[DisplayUser], Error>> {
        await userDataStore.listStream(query: .all)
    }
}

actor MockUserProvider: UserServiceProtocol, UserDataStoreProvider {

    enum Scenario {
        case infinitLoading
        case dummyData
        case error
    }

    var scenario: Scenario

    private let _dataStore: InMemoryUserDataStore = .init()
    var userDataStore: any UserDataStore { _dataStore }

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

    func fetchUsers() async throws {
        switch scenario {
        case .infinitLoading:
            // Do nothing
            try await Task.sleep(for: .seconds(24 * 60 * 60))
        case .dummyData:
            let dummyDataUrl = URL(string: "https://my.api.mockaroo.com/users.json?key=067c9730")!
            let response = try await URLSession.shared.data(from: dummyDataUrl)
            let users = try JSONDecoder().decode([DisplayUser].self, from: response.0)
            try await userDataStore.delete(query: .all)
            try await userDataStore.store(users)
        case .error:
            throw URLError(.timedOut)
        }
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
