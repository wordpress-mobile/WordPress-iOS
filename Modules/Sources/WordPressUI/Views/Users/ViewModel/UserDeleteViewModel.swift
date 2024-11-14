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
    var otherUserId: Int32 = 0

    @Published
    private(set) var otherUsers: [DisplayUser] = []

    @Published
    private(set) var deleteButtonIsDisabled: Bool = true

    private let userProvider: UserDataProvider
    private let actionDispatcher: UserManagementActionDispatcher
    let user: DisplayUser

    init(user: DisplayUser, userProvider: UserDataProvider, actionDispatcher: UserManagementActionDispatcher) {
        self.user = user
        self.userProvider = userProvider
        self.actionDispatcher = actionDispatcher
    }

    func fetchOtherUsers() async {
        withAnimation {
            isFetchingOtherUsers = true
            deleteButtonIsDisabled = true
        }

        do {
            let otherUsers = try await userProvider.fetchUsers { self.didReceiveUsers($0) }

            self.didReceiveUsers(otherUsers)
        } catch {
            withAnimation {
                self.error = error
                deleteButtonIsDisabled = true
            }
        }

        withAnimation {
            isFetchingOtherUsers = false
        }
    }

    func didReceiveUsers(_ users: [DisplayUser]) {
        withAnimation {
            if otherUserId == 0 {
                otherUserId = otherUsers.first?.id ?? 0
            }

            otherUsers = users
                .filter { $0.id != self.user.id } // Don't allow re-assigning to yourself
                .sorted(using: KeyPathComparator(\.username))
            error = nil
            deleteButtonIsDisabled = false
            isFetchingOtherUsers = false
        }
    }

    func didTapDeleteUser(callback: @escaping () -> Void) {
        debugPrint("Deleting \(user.username) and re-assigning their content to \(otherUserId)")

        withAnimation {
            error = nil
        }

        Task {
            await MainActor.run {
                withAnimation {
                    isDeletingUser = true
                }
            }

            do {
                try await actionDispatcher.deleteUser(id: user.id, reassigningPostsTo: otherUserId)
            } catch {
                debugPrint(error.localizedDescription)
                await MainActor.run {
                    withAnimation {
                        self.error = error
                    }
                }
            }

            await MainActor.run {
                withAnimation {
                    isDeletingUser = false
                    callback()
                }
            }
        }
    }
}
