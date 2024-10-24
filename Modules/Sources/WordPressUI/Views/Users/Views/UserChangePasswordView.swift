import SwiftUI
import DesignSystem

struct UserChangePasswordView: View {

    @ObservedObject
    var viewModel: UserChangePasswordViewModel

    @Environment(\.dismiss)
    var dismiss

    var body: some View {
        Form {

            if let error = viewModel.error {
                Section {
                    Text(error.localizedDescription)
                        .font(.headline)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets.zero)
            }

            Section {
                SecureField("New Password", text: $viewModel.password)
            }

            Section {
                Button(action: {
                    viewModel.didTapChangePassword {
                        self.dismiss()
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Text("Save Changes")
                            .font(.headline)
                            .padding(.DS.Padding.half)
                        Spacer()
                        if viewModel.isChangingPassword {
                            ProgressView().tint(.white)
                        }
                    }
                }).buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.zero)
        }
        .navigationTitle("Change Password")
    }
}

struct UserChangePasswordViewPreviews: PreviewProvider {

    static let viewModel = UserChangePasswordViewModel(user: DisplayUser.MockUser)

    static var previews: some View {
        NavigationStack {
            UserChangePasswordView(viewModel: viewModel)
        }
    }
}
