import SwiftUI
import WordPressCore

@MainActor
class UserDetailViewModel: ObservableObject {
    private let userService: UserServiceProtocol

    @Published
    private(set) var currentUserCanModifyUsers: Bool = false

    @Published
    private(set) var isLoadingCurrentUser: Bool = false

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    func loadCurrentUserRole() async {
        isLoadingCurrentUser = true
        defer { isLoadingCurrentUser = false}

        currentUserCanModifyUsers = await userService.isCurrentUserCapableOf("edit_users")
    }
}
