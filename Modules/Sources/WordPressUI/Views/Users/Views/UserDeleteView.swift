import SwiftUI

struct UserDeleteView: View {

    @StateObject
    var viewModel: UserDeleteViewModel

    @Environment(\.dismiss)
    var dismissAction: DismissAction

    var parentDismissAction: DismissAction?

    init(user: DisplayUser, dismiss: DismissAction? = nil) {
        _viewModel = StateObject(wrappedValue: UserDeleteViewModel(user: user))
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
                            .padding(.DS.Padding.half)
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
        UserDeleteView(user: .MockUser)
    }
}
