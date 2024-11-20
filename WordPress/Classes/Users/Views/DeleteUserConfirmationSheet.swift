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
                VStack(alignment: .leading) {
                    Text(Strings.deleteUserAttributionMessage)
                    Text("ID #\(user.id): \(user.username)")
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(.zero)

                Section {
                    if deleteUserViewModel.isFetchingOtherUsers {
                        LabeledContent(Strings.attributeContentToUserLabel) {
                            ProgressView()
                        }
                    } else {
                        Picker(Strings.attributeContentToUserLabel, selection: $deleteUserViewModel.selectedUser) {
                            ForEach(deleteUserViewModel.otherUsers) { user in
                                Text("\(user.displayName) (\(user.username))").tag(user)
                            }
                        }
                    }
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
                    .disabled(deleteUserViewModel.deleteButtonIsDisabled)
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
            value: "Attribute content to user:",
            comment: "The label that appears in the alert that appears when deleting a user"
        )

        static let deleteUserAttributionMessage = NSLocalizedString(
            "userDetails.alert.deleteUserAttributionMessage",
            value: "You have specified this user for deletion:",
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
