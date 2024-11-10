import SwiftUI

@MainActor
class UserDetailViewModel: ObservableObject {
    private let userService: UserServiceProtocol

    @Published
    private(set) var currentUserCanModifyUsers: Bool = false

    @Published
    private(set) var isLoadingCurrentUser: Bool = false

    @Published
    private(set) var error: Error? = nil

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    func loadCurrentUserRole() async {
        error = nil

        isLoadingCurrentUser = true
        defer { isLoadingCurrentUser = false}

        do {
            currentUserCanModifyUsers = try await userService.isCurrentUserCapableOf("edit_users")
        } catch {
            self.error = error
        }
    }
}
