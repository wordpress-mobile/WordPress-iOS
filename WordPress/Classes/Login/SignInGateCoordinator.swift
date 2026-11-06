import UIKit
import WordPressData
import WordPressShared

/// Shows the sign-in gate above the app's UI. Use it on the main thread.
protocol SignInGateHost: AnyObject {
    /// Whether the gate is on screen right now, regardless of what the host was last asked to do.
    var isSignInGateVisible: Bool { get }

    func showSignInGate(_ viewController: UIViewController)
    func dismissSignInGate()
}

/// Owns the WordPress.com re-authentication gate: a blocking screen, offering only Sign In and Log out, that stays
/// on top of the app while the default WordPress.com account has no token.
///
/// The gate's type names avoid "auth" because Sentry filters any string that contains it, which would hide the gate
/// from breadcrumbs.
@MainActor
final class SignInGateCoordinator {
    enum Source: String {
        case launch
        case request
        case foreground
    }

    /// Presents the WordPress.com web sign-in from the given view controller and returns when it is done.
    ///
    /// Its result is not needed: the coordinator reads the account's token afterwards, because the sign-in can
    /// store the token and then fail to load the account's sites, and a late rejection of the previous token can
    /// clear the new one while the sign-in finishes.
    typealias SignIn = @MainActor (UIViewController, WordPressDotComAuthenticator.SignInContext) async -> Void

    private enum DefaultAccountState {
        case missing
        case tokenless(userID: NSNumber?, email: String?)
        case signedIn
    }

    private enum DismissalResult: String {
        case signedIn
        case loggedOut
    }

    private let host: SignInGateHost
    private let coreDataStack: CoreDataStackSwift
    private let signIn: SignIn
    private let logOut: @MainActor () -> Void
    private var observers: [NSObjectProtocol] = []
    private var isShown = false

    init(
        host: SignInGateHost,
        coreDataStack: CoreDataStackSwift = ContextManager.shared,
        signIn: @escaping SignIn = { presenter, context in
            _ = await WordPressDotComAuthenticator().signIn(from: presenter, context: context)
        },
        logOut: @escaping @MainActor () -> Void = { AccountHelper.logOutDefaultWordPressComAccount() }
    ) {
        self.host = host
        self.coreDataStack = coreDataStack
        self.signIn = signIn
        self.logOut = logOut
    }

    func startObserving(notificationCenter: NotificationCenter = .default) {
        observers.append(
            notificationCenter.addObserver(
                forName: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Self.onMain { self?.evaluate(source: .request) }
            }
        )

        // Posted when the default account is removed, and when it gets a new token.
        observers.append(
            notificationCenter.addObserver(
                forName: .wpAccountDefaultWordPressComAccountChanged,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Self.onMain { self?.dismissIfResolved() }
            }
        )
    }

    /// Shows the gate if the default WordPress.com account has no token and the gate is not on screen. Dismisses it
    /// if the account has a token again or was removed.
    func evaluate(source: Source) {
        let state = defaultAccountState()
        guard case let .tokenless(userID, email) = state else {
            dismissIfResolved(state: state)
            return
        }
        // The host is asked rather than `isShown`: the gate's window can lose its scene, for example when the
        // system disconnects the scene in the background.
        if host.isSignInGateVisible {
            return
        }

        let viewController = SignInGateViewController(
            email: email,
            signIn: { [weak self] presenter in
                await self?.signIn(from: presenter, context: .reauthentication(userID: userID, emailHint: email))
            },
            logOut: { [weak self] in
                self?.logOut()
            }
        )
        host.showSignInGate(viewController)
        isShown = true

        Loggers.app.info("Showing the WordPress.com sign-in gate, source: \(source.rawValue)")
        WPAnalytics.track(.wpcomSignInGateShown, properties: ["source": source.rawValue])
    }

    private func signIn(from presenter: UIViewController, context: WordPressDotComAuthenticator.SignInContext) async {
        await signIn(presenter, context)
        dismissIfResolved()
    }

    private func dismissIfResolved() {
        // Skips the account lookup and keychain read when there is nothing to dismiss.
        guard isShown else {
            return
        }
        dismissIfResolved(state: defaultAccountState())
    }

    private func dismissIfResolved(state: DefaultAccountState) {
        switch state {
        case .missing:
            dismiss(result: .loggedOut)
        case .signedIn:
            dismiss(result: .signedIn)
        case .tokenless:
            break
        }
    }

    private func dismiss(result: DismissalResult) {
        guard isShown else {
            return
        }
        host.dismissSignInGate()
        isShown = false

        Loggers.app.info("Dismissed the WordPress.com sign-in gate, result: \(result.rawValue)")
        WPAnalytics.track(.wpcomSignInGateDismissed, properties: ["result": result.rawValue])
    }

    private func defaultAccountState() -> DefaultAccountState {
        coreDataStack.performQuery { context in
            guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
                return .missing
            }
            // Read the keychain, because another context may have changed the token without invalidating the
            // token cache of this context's account instance.
            if let token = account.authTokenInKeychain, !token.isEmpty {
                return .signedIn
            }
            return .tokenless(userID: account.userID, email: account.email)
        }
    }

    /// Observers use this instead of `queue: .main`, which can deadlock. A post from another thread waits until the
    /// main queue runs the observer. The invalid-token handler posts the sign-in notification inside a
    /// `performAndWait` on the account's context while the main thread waits for it (see
    /// `WPAccount.wordPressComRestApi`), so a background context would never get to return.
    private nonisolated static func onMain(_ body: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            DispatchQueue.main.async { body() }
        }
    }
}
