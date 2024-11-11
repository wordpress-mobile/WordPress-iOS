import SwiftUI

public class UserChangePasswordViewModel: ObservableObject {

    public enum Errors: LocalizedError {
        case passwordMustNotBeEmpty

        public var errorDescription: String? {
            switch self {
                case .passwordMustNotBeEmpty: NSLocalizedString(
                    "userchangepassword.error.empty",
                    value: "Password must not be empty",
                    comment: "An error message that appears when an empty password has been entered"
                )
            }
        }
    }

    @Published
    var password: String = ""

    @Published
    var isChangingPassword: Bool = false

    @Published
    var error: Error? = nil

    @Environment(\.dismiss)
    var dismissAction

    private let actionDispatcher: UserManagementActionDispatcher
    let user: DisplayUser

    init(user: DisplayUser, actionDispatcher: UserManagementActionDispatcher) {
        self.user = user
        self.actionDispatcher = actionDispatcher
    }

    func didTapChangePassword(callback: @escaping () -> Void) {

        if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            withAnimation {
                error = Errors.passwordMustNotBeEmpty
            }
            return
        }

        withAnimation {
            error = nil
        }

        Task {
            await MainActor.run {
                withAnimation {
                    self.isChangingPassword = true
                }
            }

            do {
                try await actionDispatcher.setNewPassword(id: user.id, newPassword: password)
            } catch {
                self.error = error
            }

            await MainActor.run {
                withAnimation {
                    self.isChangingPassword = false
                }
            }

            await MainActor.run {
                callback()
            }
        }
    }
}
