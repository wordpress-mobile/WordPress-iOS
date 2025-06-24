import Foundation
import GravatarUI
import WordPressData
import WordPressShared
import WordPressAuthenticator
import AsyncImageKit

@MainActor
struct GravatarQuickEditorPresenter {
    let email: String
    let authToken: String
    let emailVerificationStatus: WPAccount.VerificationStatus

    let onAccountUpdated: (() -> Void)?

    init?(onAccountUpdated: (() -> Void)? = nil) {
        let context = ContextManager.shared.mainContext
        guard
            let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context),
            let authToken = account.authToken,
            let email = account.email
        else {
            return nil
        }
        self.email = email
        self.authToken = authToken
        self.emailVerificationStatus = account.verificationStatus
        self.onAccountUpdated = onAccountUpdated
    }

    func presentQuickEditor(on presentingViewController: UIViewController, scope: QuickEditorScopeOption) {
        guard emailVerificationStatus == .verified else {
            presentAlert(on: presentingViewController)
            return
        }
        let presenter = QuickEditorPresenter(
            email: Email(email),
            scopeOption: scope,
            token: authToken
        )
        presenter.present(
            in: presentingViewController,
            onUpdate: { update in
                switch update {
                case is QuickEditorUpdate.Avatar:
                    onAvatarUpdate()
                case is QuickEditorUpdate.AboutInfo:
                    onAccountUpdated?()
                default: break
                }
            }, onDismiss: {
                // No op.
            }
        )
    }

    private func presentAlert(on presentingViewController: UIViewController) {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString(
                "profile.update.email.verification.required",
                value: "To update your profile, you need to verify your email address first.",
                comment: "An error message displayed when attempting to update their profile while the user's email address is not verified."
            ),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: SharedStrings.Button.ok, style: .default))
        presentingViewController.present(alert, animated: true)
    }

    private func onAvatarUpdate() {
        AuthenticatorAnalyticsTracker.shared.track(click: .selectAvatar)
        Task {
            // Purge the cache otherwise the old avatars remain around.
            await ImageDownloader.shared.clearURLSessionCache()
            await ImageDownloader.shared.clearMemoryCache()
            NotificationCenter.default.post(
                name: .GravatarQEAvatarUpdateNotification,
                object: self,
                userInfo: [GravatarQEAvatarUpdateNotificationKeys.email.rawValue: email]
            )
        }
    }
}
