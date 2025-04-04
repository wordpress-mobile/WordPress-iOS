import UIKit
import WordPressData

struct AuthTokenIssueSolver {
    private let coreData: CoreDataStack

    init(coreData: CoreDataStack = ContextManager.shared) {
        self.coreData = coreData
    }

    /// - note: The completion callback is run immediatelly if there is no issue.
    func fixAuthTokenIssueIfNeeded(in window: UIWindow, _ completion: @escaping () -> Void) {
        guard hasAuthTokenIssues() else {
            completion()
            return
        }

        let signInVC = WordPressAuthenticationManager.signinForWPComFixingAuthToken { cancelled in
            if cancelled {
                // We present asynchronously to prevent an issue where the Login VC would dismiss the
                // alert instead of itself.
                DispatchQueue.main.async {
                    showCancelReAuthenticationAlert(in: window, onDeletionConfirmed: {
                        let accountService = AccountService(coreDataStack: ContextManager.sharedInstance())
                        accountService.removeDefaultWordPressComAccount()
                        completion()
                    })
                }
            } else {
                completion()
            }
        }

        window.rootViewController = signInVC

        showExplanationAlertForReAuthentication(in: signInVC)
    }

    /// Call this method to know if the local installation of WPiOS has the
    /// authToken issue this class was designed to solve.
    /// - returns: `true` if the local WPiOS installation needs to be fixed by this class.
    private func hasAuthTokenIssues() -> Bool {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: coreData.mainContext) else {
            return false
        }
        return account.authToken == nil
    }

    private func showCancelReAuthenticationAlert(in window: UIWindow, onDeletionConfirmed: @escaping () -> Void) {
        let alert = UIAlertController(
            title: Strings.CancelAlert.title,
            message: Strings.CancelAlert.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: SharedStrings.Button.cancel, style: .cancel) { _ in })
        alert.addAction(UIAlertAction(title: SharedStrings.Button.delete, style: .destructive) { _ in
            onDeletionConfirmed()
        })

        window.rootViewController?.present(alert, animated: true, completion: nil)
    }

    private func showExplanationAlertForReAuthentication(in presentingViewController: UIViewController) {
        let alert = UIAlertController(
            title: Strings.ExplanationAlert.title,
            message: Strings.ExplanationAlert.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: SharedStrings.Button.ok, style: .default) { _ in })
        alert.modalPresentationStyle = .popover

        presentingViewController.present(alert, animated: true)
    }

    private enum Strings {
        enum CancelAlert {
            static let title = NSLocalizedString(
                "authTokenIssueSolver.cancelAlert.title",
                value: "Careful!",
                comment: "Title for the warning shown to the user when he refuses to re-login when the authToken is missing."
            )
            static let message = NSLocalizedString(
                "authTokenIssueSolver.cancelAlert.message",
                value: "Proceeding will remove all WordPress.com data from this device, and delete any locally saved drafts. You will not lose anything already saved to your WordPress.com blog(s).",
                comment: "Message for the warning shown to the user when he refuses to re-login when the authToken is missing."
            )
        }

        enum ExplanationAlert {
            static let title = NSLocalizedString(
                "authTokenIssueSolver.explanationAlert.title",
                value: "Oops!",
                comment: "Title for the warning shown to the user when the app realizes there should be an auth token but there isn't one."
            )
            static let message = NSLocalizedString(
                "authTokenIssueSolver.explanationAlert.title",
                value: "There was a problem connecting to WordPress.com. Please log in again.",
                comment: "Message for the warning shown to the user when the app realizes there should be an auth token but there isn't one."
            )
        }
    }
}
