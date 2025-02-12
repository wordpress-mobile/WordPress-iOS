import Foundation
import Combine
import WordPressAPI

/// UserService is responsible for fetching user acounts via the .org REST API – it's the replacement for `UsersService` (the XMLRPC-based approach)
///
public actor UserService: UserServiceProtocol {
    private let client: WordPressClient
    private let userDataStore: InMemoryUserDataStore = .init()

    private var _currentUser: UserWithEditContext?
    private var currentUser: UserWithEditContext? {
        get async {
            if _currentUser == nil {
                _currentUser = try? await self.client.api.users.retrieveMeWithEditContext().data
            }
            return _currentUser
        }
    }

    public init(client: WordPressClient) {
        self.client = client
    }

    public func fetchUsers() async throws {
        let sequence = await client.api.users.sequenceWithEditContext(params: .init(perPage: 100))
        var started = false
        for try await users in sequence {
            if !started {
                try await userDataStore.delete(query: .all)
            }

            try await userDataStore.store(users.compactMap { DisplayUser(user: $0) })

            started = true
        }
    }

    public func isCurrentUserCapableOf(_ capability: String) async -> Bool {
        await currentUser?.capabilities.keys.contains(capability) == true
    }

    public func deleteUser(id: Int64, reassigningPostsTo newUserId: Int64) async throws {
        let result = try await client.api.users.delete(
            userId: id,
            params: UserDeleteParams(reassign: newUserId)
        ).data

        // Remove the deleted user from the cached users list.
        if result.deleted {
            try await userDataStore.delete(query: .id(id))
        }
    }

    public func setNewPassword(id: Int64, newPassword: String) async throws {
        _ = try await client.api.users.update(
            userId: id,
            params: UserUpdateParams(password: newPassword)
        )
    }

    public func allUsers() async throws -> [DisplayUser] {
        try await userDataStore.list(query: .all)
    }

    public func streamSearchResult(input: String) async -> AsyncStream<Result<[DisplayUser], Error>> {
        await userDataStore.listStream(query: .search(input))
    }

    public func streamAll() async -> AsyncStream<Result<[DisplayUser], Error>> {
        await userDataStore.listStream(query: .all)
    }

}

private extension DisplayUser {
    init?(user: UserWithEditContext) {
        guard let role = user.roles.first else {
            return nil
        }

        self.init(
            id: user.id,
            handle: user.slug,
            username: user.username,
            firstName: user.firstName,
            lastName: user.lastName,
            displayName: user.name,
            profilePhotoUrl: Self.profilePhotoUrl(for: user),
            role: role,
            emailAddress: user.email,
            websiteUrl: user.link,
            biography: user.description
        )
    }

    static func profilePhotoUrl(for user: UserWithEditContext) -> URL? {
        guard let url = user.avatarUrls?[.size96] ?? user.avatarUrls?[.size48] ?? user.avatarUrls?[.size24], let url else {
            return nil
        }

        return URL(string: url)
    }
}
