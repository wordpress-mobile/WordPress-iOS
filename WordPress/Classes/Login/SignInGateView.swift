import SwiftUI
import UIKit

/// Hosts the screen of the WordPress.com re-authentication gate. See `SignInGateCoordinator`.
final class SignInGateViewController: UIHostingController<SignInGateView> {
    let viewModel: SignInGateViewModel

    init(
        email: String?,
        signIn: @escaping @MainActor (UIViewController) async -> Void,
        logOut: @escaping @MainActor () -> Void
    ) {
        viewModel = SignInGateViewModel(email: email, signIn: signIn, logOut: logOut)
        super.init(rootView: SignInGateView(viewModel: viewModel))
        viewModel.presenter = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // VoiceOver must not reach the app UI in the window below the gate.
        view.accessibilityViewIsModal = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Moves VoiceOver focus to the first element, the message.
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
}

@MainActor
final class SignInGateViewModel: ObservableObject {
    let email: String?
    @Published private(set) var isSigningIn = false

    /// The view controller that presents the web sign-in, and any error alert, above the gate.
    weak var presenter: UIViewController?

    private let signIn: @MainActor (UIViewController) async -> Void
    private let logOut: @MainActor () -> Void

    init(
        email: String?,
        signIn: @escaping @MainActor (UIViewController) async -> Void,
        logOut: @escaping @MainActor () -> Void
    ) {
        self.email = email
        self.signIn = signIn
        self.logOut = logOut
    }

    /// Returns the sign-in task, or `nil` when a sign-in is already in progress.
    @discardableResult
    func signInTapped() -> Task<Void, Never>? {
        guard !isSigningIn, let presenter else {
            return nil
        }
        isSigningIn = true
        return Task {
            await signIn(presenter)
            isSigningIn = false
        }
    }

    func logOutTapped() {
        // A sign-in that is still finishing would store the account again after the log out.
        guard !isSigningIn else {
            return
        }
        logOut()
    }
}

struct SignInGateView: View {
    @ObservedObject var viewModel: SignInGateViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("wp-logotype")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 48)
                .accessibilityHidden(true)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                viewModel.signInTapped()
            } label: {
                // The hidden title keeps the button's height while the spinner shows.
                Text(Strings.signIn)
                    .opacity(viewModel.isSigningIn ? 0 : 1)
                    .overlay {
                        if viewModel.isSigningIn {
                            ProgressView()
                        }
                    }
            }
            .buttonStyle(ContinueWithWordPressDotComButtonStyle())
            .disabled(viewModel.isSigningIn)
            // The button shows only a spinner while loading.
            .accessibilityLabel(Strings.signIn)

            Button(role: .destructive) {
                viewModel.logOutTapped()
            } label: {
                Text(Strings.logOut)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isSigningIn)
        }
        .padding()
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var message: AttributedString {
        guard let email = viewModel.email else {
            return AttributedString(Strings.message)
        }
        var message = AttributedString(String.localizedStringWithFormat(Strings.messageWithEmail, email))
        if let range = message.range(of: email) {
            message[range].inlinePresentationIntent = .stronglyEmphasized
        }
        return message
    }
}

/// Looks like the login prologue's "Continue with WordPress.com" button, a UIKit button, by reading its configuration.
private struct ContinueWithWordPressDotComButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let prologueButton = LoginPrologueViewController.buttonConfiguration(
            title: "",
            isPrimary: true,
            highlighted: configuration.isPressed
        )
        let foregroundColor = Color(uiColor: prologueButton.baseForegroundColor ?? .white)
        let insets = prologueButton.contentInsets

        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(foregroundColor)
            .tint(foregroundColor)
            .padding(
                EdgeInsets(top: insets.top, leading: insets.leading, bottom: insets.bottom, trailing: insets.trailing)
            )
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: prologueButton.background.cornerRadius)
                    .fill(Color(uiColor: prologueButton.baseBackgroundColor ?? .clear))
            )
    }
}

private enum Strings {
    static let message = NSLocalizedString(
        "wpcom.signInGate.message",
        value: "Your WordPress.com sign-in is no longer valid. Sign in again to continue.",
        comment: "Message on the screen shown when the user's WordPress.com sign-in is no longer valid."
    )
    static let messageWithEmail = NSLocalizedString(
        "wpcom.signInGate.messageWithEmail",
        value: "Your WordPress.com sign-in is no longer valid. Sign in with %1$@ to continue.",
        comment:
            "Message on the screen shown when the user's WordPress.com sign-in is no longer valid. %1$@ is the email address of the account to sign in with."
    )
    static let signIn = NSLocalizedString(
        "wpcom.token.alert.button.signin",
        value: "Sign In",
        comment: "Button title to Sign In to WordPress.com"
    )
    static let logOut = NSLocalizedString(
        "wpcom.token.alert.button.logout",
        value: "Log out",
        comment: "Button title to log out the current WordPress.com account"
    )
}

#Preview {
    SignInGateView(
        viewModel: SignInGateViewModel(email: "user@example.com", signIn: { _ in }, logOut: {})
    )
}
