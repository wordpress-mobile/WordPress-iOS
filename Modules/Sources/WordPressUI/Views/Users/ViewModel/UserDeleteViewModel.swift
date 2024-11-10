import SwiftUI

@MainActor
public class UserDeleteViewModel: ObservableObject {

    @Published
    private(set) var isFetchingOtherUsers: Bool = false

    @Published
    private(set) var isDeletingUser: Bool = false

    @Published
    private(set) var error: Error? = nil

    @Published
    var selectedUser: DisplayUser? = nil

    @Published
    private(set) var otherUsers: [DisplayUser] = []

    @Published
    private(set) var deleteButtonIsDisabled: Bool = true

    private let userService: UserServiceProtocol
    let user: DisplayUser

    init(user: DisplayUser, userService: UserServiceProtocol) {
        self.user = user
        self.userService = userService

        // Update `otherUsers` whenever there is a successful fetch of users.
        userService.users.compactMap { [weak self] in
            guard let self, let users = try? $0.get() else { return nil }

            return users
                .filter { $0.id != self.user.id } // Don't allow re-assigning to yourself
                .sorted(using: KeyPathComparator(\.username))
        }
        .assign(to: &$otherUsers)

        // Update `error` whenever there is a failure in fetching users.
        userService.users.compactMap {
            if case let .failure(error) = $0 { return error }
            return nil
        }
        .assign(to: &$error)

        // Default `selectedUser` to be the first one in `otherUsers`.
        // Using Combine here because `didSet` observers don't work with `@Published` properties.
        //
        // The implementation is equivalent to `if selectedUser == nil { selectedUser = otherUsers.first }`
        $otherUsers.combineLatest($selectedUser)
            .filter { _, selectedUser in selectedUser == nil }
            .map { others, _ in others.first }
            .assign(to: &$selectedUser)

    }

    func fetchOtherUsers() {
        isFetchingOtherUsers = true
        deleteButtonIsDisabled = true

        userService.fetchUsers()

        let fetched = userService.users.first()

        fetched
            .map { _ in false }
            .assign(to: &$isFetchingOtherUsers)
        fetched
            .map { (try? $0.get()) == nil }
            .assign(to: &$deleteButtonIsDisabled)
    }

    func deleteUser() async throws {
        guard let otherUserId = selectedUser?.id, otherUserId != user.id else { return }

        isDeletingUser = true
        defer { isDeletingUser = false }

        try await userService.deleteUser(id: user.id, reassigningPostsTo: otherUserId)
    }
}
