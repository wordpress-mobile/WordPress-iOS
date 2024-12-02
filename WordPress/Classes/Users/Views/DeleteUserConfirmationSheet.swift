import Foundation
import SwiftUI

struct DeleteUserConfirmationSheet: View {
    let user: DisplayUser

    @ObservedObject
    var deleteUserViewModel: UserDeleteViewModel

    let didTapDeleteButton: () -> Void

    @Environment(\.dismiss)
    private var dismissAction: DismissAction

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(Strings.attributeContentToUserLabel, selection: $deleteUserViewModel.selectedUser) {
                        ForEach(deleteUserViewModel.otherUsers) { user in
                            Text("\(user.displayName) (\(user.username))").tag(user)
                        }
                    }
                } header: {
                    Text(Strings.deleteUserAttributionMessage)
                        .font(.body)
                        .textCase(nil)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 8)
                } footer: {
                    Text(Strings.attributeContentHellpMessage)
                }
            }
            .navigationTitle(Strings.attributeContentConfirmationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismissAction()
                    } label: {
                        Text(Strings.attributeContentConfirmationCancelButton)
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        didTapDeleteButton()
                    } label: {
                        Text(Strings.attributeContentConfirmationDeleteButton)
                    }
                }
            }
            .onAppear {
                Task {
                    if deleteUserViewModel.otherUsers.isEmpty {
                        await deleteUserViewModel.fetchOtherUsers()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    enum Strings {
        static let attributeContentToUserLabel = NSLocalizedString(
            "userDetails.alert.attributeContentToUserLabel",
            value: "Selected user",
            comment: "The label that appears in the alert that appears when deleting a user"
        )

        static let attributeContentHellpMessage = NSLocalizedString(
            "userDetails.alert.attributeContentToUserHelpMessage",
            value: "Pages and posts belonging to the deleted user will have their author changed to the user you select in the provided dropdown.",
            comment: "The help message for reassigning content to a user after deletion."
        )

        static let deleteUserAttributionMessage = NSLocalizedString(
            "userDetails.alert.deleteUserAttributionMessage",
            value: "Select another user to attribute this content to.",
            comment: "The message that appears when deleting a user."
        )

        static let attributeContentConfirmationTitle = NSLocalizedString(
            "userDetails.alert.deleteUserConfirmationTitle",
            value: "Delete Confirmation",
            comment: "The title of the confirmation alert that appears when deleting a user"
        )

        static let attributeContentConfirmationCancelButton = NSLocalizedString(
            "userDetails.alert.deleteUserConfirmationCancelButton",
            value: "Cancel",
            comment: "The title of the cancel button in the confirmation alert that appears when deleting a user"
        )

        static let attributeContentConfirmationDeleteButton = NSLocalizedString(
            "userDetails.alert.deleteUserConfirmationDeleteButton",
            value: "Delete",
            comment: "The title of the delete button in the confirmation alert that appears when deleting a user"
        )
    }
}

#Preview {
    DeleteUserConfirmationSheet(user: .MockUser, deleteUserViewModel: .init(user: .MockUser, userService: MockUserProvider()), didTapDeleteButton: { })
}
