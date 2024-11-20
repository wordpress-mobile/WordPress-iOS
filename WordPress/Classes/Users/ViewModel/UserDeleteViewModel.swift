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

        // Default `selectedUser` to be the first one in `otherUsers`.
        // Using Combine here because `didSet` observers don't work with `@Published` properties.
        //
        // The implementation is equivalent to `if selectedUser == nil { selectedUser = otherUsers.first }`
        $otherUsers.combineLatest($selectedUser)
            .filter { _, selectedUser in selectedUser == nil }
            .map { others, _ in others.first }
            .assign(to: &$selectedUser)

    }

    func fetchOtherUsers() async {
        isFetchingOtherUsers = true
        deleteButtonIsDisabled = true

        defer {
            isFetchingOtherUsers = false
            deleteButtonIsDisabled = otherUsers.isEmpty
        }

        do {
            let users = try await userService.fetchUsers()
            self.otherUsers = users
                .filter { $0.id != self.user.id } // Don't allow re-assigning to yourself
                .sorted(using: KeyPathComparator(\.username))
        } catch {
            self.error = error
        }
    }

    func deleteUser() async throws {
        guard let otherUserId = selectedUser?.id, otherUserId != user.id else { return }

        isDeletingUser = true
        defer { isDeletingUser = false }

        try await userService.deleteUser(id: user.id, reassigningPostsTo: otherUserId)
    }
}
