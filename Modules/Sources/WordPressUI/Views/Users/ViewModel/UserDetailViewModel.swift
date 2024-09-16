import SwiftUI

@MainActor
class UserDetailViewModel: ObservableObject {

    @Published
    var currentUserCanModifyUsers: Bool = false

    @Published
    var isLoadingCurrentUser: Bool = false

    @Published
    var error: Error? = nil

    func loadCurrentUserRole() async {
        withAnimation {
            isLoadingCurrentUser = true
        }

        do {
            let hasPermissions = try await UserObjectResolver.userProvider.fetchCurrentUserCan("edit_users")
            error = nil

            withAnimation {
                currentUserCanModifyUsers = hasPermissions
            }
        } catch {
            withAnimation {
                self.error = error
            }
        }

        withAnimation {
            isLoadingCurrentUser = false
        }
    }
}
