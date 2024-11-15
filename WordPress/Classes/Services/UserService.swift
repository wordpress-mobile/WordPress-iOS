import Foundation
import Combine
import WordPressAPI
import WordPressUI

/// UserService is responsible for fetching user acounts via the .org REST API – it's the replacement for `UsersService` (the XMLRPC-based approach)
///
actor UserService: UserServiceProtocol {
    private let client: WordPressClient

    private var fetchUsersTask: Task<[DisplayUser], Error>?

    private(set) var users: [DisplayUser]? {
        didSet {
            if let users {
                usersUpdatesContinuation.yield(users)
            }
        }
    }
    nonisolated let usersUpdates: AsyncStream<[DisplayUser]>
    private nonisolated let usersUpdatesContinuation: AsyncStream<[DisplayUser]>.Continuation

    private var currentUser: UserWithEditContext?

    init(client: WordPressClient) {
        self.client = client
        (usersUpdates, usersUpdatesContinuation) = AsyncStream<[DisplayUser]>.makeStream()
    }

    deinit {
        usersUpdatesContinuation.finish()
        fetchUsersTask?.cancel()
    }

    func fetchUsers() async throws -> [DisplayUser] {
        let users = try await createFetchUsersTaskIfNeeded().value
        self.users = users
        return users
    }

    private func createFetchUsersTaskIfNeeded() -> Task<[DisplayUser], Error> {
        if let fetchUsersTask {
            return fetchUsersTask
        }
        let task = Task { [client] in
            try await client
                .api
                .users
                .listWithEditContext(params: UserListParams(perPage: 100))
                .compactMap { DisplayUser(user: $0) }
        }
        fetchUsersTask = task
        return task
    }

    func isCurrentUserCapableOf(_ capability: String) async throws -> Bool {
        let currentUser: UserWithEditContext
        if let cached = self.currentUser {
            currentUser = cached
        } else {
            currentUser = try await self.client.api.users.retrieveMeWithEditContext()
            self.currentUser = currentUser
        }

        return currentUser.capabilities.keys.contains(capability)
    }

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
        let result = try await client.api.users.delete(
            userId: id,
            params: UserDeleteParams(reassign: newUserId)
        )

        // Remove the deleted user from the cached users list.
        if result.deleted, let index = users?.firstIndex(where: { $0.id == id }) {
            users?.remove(at: index)
        }
    }

    func setNewPassword(id: Int32, newPassword: String) async throws {
        _ = try await client.api.users.update(
            userId: Int32(id),
            params: UserUpdateParams(password: newPassword)
        )
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
        // The key is the size of the avatar. Get the largetst one, which is 96x96px.
        // https://github.com/WordPress/wordpress-develop/blob/6.6.2/src/wp-includes/rest-api.php#L1253-L1260
        guard let url = user.avatarUrls?
            .max(by: { $0.key.compare($1.key, options: .numeric) == .orderedAscending } )?
            .value
        else { return nil }

        return URL(string: url)
    }
}
