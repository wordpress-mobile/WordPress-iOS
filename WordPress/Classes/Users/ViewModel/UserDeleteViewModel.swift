import SwiftUI
import WordPressCore

@MainActor
public class UserDeleteViewModel: ObservableObject {

    @Published
    private(set) var isDeletingUser: Bool = false

    @Published
    private(set) var error: Error? = nil

    @Published
    var selectedUser: DisplayUser? = nil

    @Published
    private(set) var otherUsers: [DisplayUser] = [] {
        didSet {
            if selectedUser == nil {
                selectedUser = otherUsers.first
            }
        }
    }

    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    func fetchOtherUsers(excluding user: DisplayUser) async {
        do {
            self.otherUsers = try await userService.allUsers()
                .filter { $0.id != user.id } // Don't allow re-assigning to yourself
                .sorted(using: KeyPathComparator(\.username))
        } catch {
            self.error = error
        }
    }

    func delete(user: DisplayUser) async throws {
        guard let otherUserId = selectedUser?.id, otherUserId != user.id else { return }

        isDeletingUser = true
        defer { isDeletingUser = false }

        try await userService.deleteUser(id: user.id, reassigningPostsTo: otherUserId)
    }
}
