import SwiftUI
import AuthenticationServices
import WordPressAPI
import WordPressAuthenticator
import WordPressData
import DesignSystem
import WordPressShared

struct LoginWithUrlView: View {

    weak var presenter: UIViewController?
    let loginCompleted: (TaggedManagedObjectID<Blog>) -> Void

    @State fileprivate var errorMessage: String?
    @State private var urlField: String = ""
    @State private var isLoading = false

    @Environment(\.dismiss) var dismiss

    private var isContinueButtonDisabled: Bool {
        isLoading || urlField.trim().isEmpty
    }

    var body: some View {
        VStack(alignment: .leading) {
            Image("splashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(Self.enterSiteAddress)

            siteAdddressTextField()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Spacer()

            DSButton(
                title: SharedStrings.Button.continue,
                style: DSButtonStyle(emphasis: .primary, size: .large),
                isLoading: .constant(isLoading),
                action: startLogin
            )
            .disabled(isContinueButtonDisabled)
        }
        .padding()
        .navigationTitle(Self.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func siteAdddressTextField() -> some View {
        TextField(text: $urlField) {
            Text("example.com")
        }
        .padding(.top)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) { Divider() }
        .overlay(Divider(), alignment: .bottom)
        .tint(.green)
        .textContentType(.URL)
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
        .onSubmit(startLogin)
        .disabled(isLoading)
    }

    private func startLogin() {
        errorMessage = nil
        isLoading = true

        // The Swift compiler isn't happy about placing this do-catch function body inside a Task.
        // https://github.com/swiftlang/swift/issues/76807
        func login() async {
            guard let presenter else {
                wpAssertionFailure("No presenter assigned")
                return
            }

            do {
                let blog = try await SelfHostedSiteAuthenticator()
                    .signIn(site: urlField, from: presenter, context: .default)

                dismiss()
                self.loginCompleted(blog)
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }

        Task { @MainActor in
            await login()
        }
    }
}

private extension LoginWithUrlView {
    static var title: String { NSLocalizedString("addSite.selfHosted.title", value: "Add Self-Hosted Site", comment: "Title of the page to add a self-hosted site") }
    static var enterSiteAddress: String { NSLocalizedString("addSite.selfHosted.enterSiteAddress", value: "Enter the address of the WordPress site you'd like to connect.", comment: "A message to inform users to type the site address in the text field.") }
}

// MARK: - SwiftUI Preview

#Preview {
    LoginWithUrlView(presenter: nil) { _ in }
}
