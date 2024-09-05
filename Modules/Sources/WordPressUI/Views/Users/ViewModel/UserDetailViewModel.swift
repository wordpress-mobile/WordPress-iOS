import SwiftUI

class UserDetailViewModel: ObservableObject {

    @Published
    var currentUserCanModifyUsers: Bool = false

    @Published
    var isLoadingCurrentUser: Bool = false

    @Published
    var error: Error? = nil

    func loadCurrentUserRole() async {
        await MainActor.run {
            withAnimation {
                self.isLoadingCurrentUser = true
            }
        }

        do {
            let hasPermissions = try await UserObjectResolver.userProvider.fetchCurrentUserCan("edit_users")
            self.error = nil

            await MainActor.run {
                withAnimation {
                    self.currentUserCanModifyUsers = hasPermissions
                }
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    self.error = error
                }
            }
        }

        await MainActor.run {
            withAnimation {
                self.isLoadingCurrentUser = false
            }
        }
    }
}
