import SwiftUI

struct UserDeleteView: View {

    @StateObject
    private var viewModel: UserDeleteViewModel
    private let userProvider: UserDataProvider
    private let actionDispatcher: UserManagementActionDispatcher

    @Environment(\.dismiss)
    var dismissAction: DismissAction

    var parentDismissAction: DismissAction?

    init(user: DisplayUser, userProvider: UserDataProvider, actionDispatcher: UserManagementActionDispatcher, dismiss: DismissAction? = nil) {
        self.userProvider = userProvider
        self.actionDispatcher = actionDispatcher
        _viewModel = StateObject(wrappedValue: UserDeleteViewModel(user: user, userProvider: userProvider, actionDispatcher: actionDispatcher))
        parentDismissAction = dismiss
    }

    var body: some View {
        Form {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
            else if viewModel.isFetchingOtherUsers {
                LabeledContent("Attribute all content to:") {
                    ProgressView()
                }
            } else {
                Picker("Attribute all content to:", selection: $viewModel.otherUserId.animation()) {
                    ForEach(viewModel.otherUsers) { user in
                        Text(user.username).tag(user.id)
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    viewModel.didTapDeleteUser {
                        self.dismissAction()
                        self.parentDismissAction?()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete User")
                            .font(.headline)
                            .padding(4)
                        Spacer()
                        if viewModel.isDeletingUser {
                            ProgressView().tint(.white)
                        }
                    }
                }.buttonStyle(.borderedProminent)
                .disabled(viewModel.deleteButtonIsDisabled)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.zero)
        }
        .navigationTitle("Delete User")
        .task { await viewModel.fetchOtherUsers() }
    }
}

#Preview {
    NavigationStack {
        UserDeleteView(user: .MockUser, userProvider: MockUserProvider(), actionDispatcher: UserManagementActionDispatcher())
    }
}
