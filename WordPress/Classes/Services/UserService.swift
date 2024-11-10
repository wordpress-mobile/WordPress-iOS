import Foundation
import Combine
import WordPressAPI
import WordPressUI

/// UserService is responsible for fetching user acounts via the .org REST API – it's the replacement for `UsersService` (the XMLRPC-based approach)
///
class UserService: UserServiceProtocol {
    private let client: WordPressClient
    private let currentUserId: Int

    private let fetchUserslock = NSRecursiveLock()
    private var fetchUsersTask: Task<Void, Error>?

    private let usersSubject: CurrentValueSubject<Result<[WordPressUI.DisplayUser], any Error>, Never> = .init(.success([]))
    var users: AnyPublisher<Result<[WordPressUI.DisplayUser], any Error>, Never> {
        usersSubject.dropFirst().eraseToAnyPublisher()
    }

    init(api: WordPressClient, currentUserId: Int) {
        self.client = api
        self.currentUserId = currentUserId
    }

    deinit {
        fetchUsersTask?.cancel()
    }

    func fetchUsers() {
        fetchUserslock.lock()
        defer { fetchUserslock.unlock() }

        guard fetchUsersTask == nil else { return }

        fetchUsersTask = Task.detached {
            do {
                let users: [DisplayUser] = try await self.client
                    .api
                    .users
                    .listWithEditContext(params: UserListParams(perPage: 100))
                    .compactMap { DisplayUser(user: $0) }
                self.finishFetchingUsers(.success(users))
            } catch {
                self.finishFetchingUsers(.failure(error))
            }
        }
    }

    private func finishFetchingUsers(_ result: Result<[DisplayUser], Error>) {
        fetchUserslock.lock()
        defer { fetchUserslock.unlock() }

        fetchUsersTask = nil

        DispatchQueue.main.async {
            self.usersSubject.send(result)
        }
    }

    func isCurrentUserCapableOf(_ capability: String) async throws -> Bool {
        // TODO: Cache the current user?
        try await client.api.users.retrieveMeWithEditContext().capabilities.keys.contains(capability)
    }

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
        let result = try await client.api.users.delete(
            userId: id,
            params: UserDeleteParams(reassign: newUserId)
        )

        // Remove the deleted user from the cached users list.
        if result.deleted {
            await MainActor.run {
                if case var .success(fetched) = usersSubject.value, let index = fetched.firstIndex(where: { $0.id == id }) {
                    fetched.remove(at: index)
                    usersSubject.send(.success(fetched))
                }
            }
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
