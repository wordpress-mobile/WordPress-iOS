import Foundation
import Combine
import WordPressAPI
import WordPressUI

/// UserService is responsible for fetching user acounts via the .org REST API – it's the replacement for `UsersService` (the XMLRPC-based approach)
///
actor UserService: UserServiceProtocol, UserDataStoreProvider {
    private let client: WordPressClient

    private let _dataStore: InMemoryUserDataStore = .init()
    var userDataStore: any UserDataStore { _dataStore }

    private var _currentUser: UserWithEditContext?
    private var currentUser: UserWithEditContext? {
        get async {
            if _currentUser == nil {
                _currentUser = try? await self.client.api.users.retrieveMeWithEditContext().data
            }
            return _currentUser
        }
    }

    init(client: WordPressClient) {
        self.client = client
    }

    func fetchUsers() async throws {
        let sequence = await client.api.users.sequenceWithEditContext(params: .init(perPage: 100))
        var started = false
        for try await users in sequence {
            if !started {
                try await _dataStore.delete(query: .all)
            }

            try await _dataStore.store(users.compactMap { DisplayUser(user: $0) })

            started = true
        }
    }

    func isCurrentUserCapableOf(_ capability: String) async -> Bool {
        await currentUser?.capabilities.keys.contains(capability) == true
    }

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
        let result = try await client.api.users.delete(
            userId: id,
            params: UserDeleteParams(reassign: newUserId)
        ).data

        // Remove the deleted user from the cached users list.
        if result.deleted {
            try await _dataStore.delete(query: .id([id]))
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
