import Foundation
import GravatarUI
import WordPressShared
import WordPressAuthenticator
import AsyncImageKit

@MainActor
struct GravatarQuickEditorPresenter {
    let email: String
    let authToken: String
    let emailVerificationStatus: WPAccount.VerificationStatus

    init?(email: String) {
        let context = ContextManager.shared.mainContext
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context), let authToken = account.authToken else {
            return nil
        }
        self.email = email
        self.authToken = authToken
        self.emailVerificationStatus = account.verificationStatus
    }

    func presentQuickEditor(on presentingViewController: UIViewController) {
        guard emailVerificationStatus == .verified else {
            let alert = UIAlertController(
                title: nil,
                message: NSLocalizedString(
                    "avatar.update.email.verification.required",
                    value: "To update your avatar, you need to verify your email address first.",
                    comment: "An error message displayed when attempting to update an avatar while the user's email address is not verified."
                ),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: SharedStrings.Button.ok, style: .default))
            presentingViewController.present(alert, animated: true)
            return
        }
        let presenter = QuickEditorPresenter(
            email: Email(email),
            scope: .avatarPicker(AvatarPickerConfiguration(contentLayout: .horizontal())),
            configuration: .init(
                interfaceStyle: presentingViewController.traitCollection.userInterfaceStyle
            ),
            token: authToken
        )
        presenter.present(
            in: presentingViewController,
            onAvatarUpdated: {
                AuthenticatorAnalyticsTracker.shared.track(click: .selectAvatar)
                Task {
                    // Purge the cache otherwise the old avatars remain around.
                    await ImageDownloader.shared.clearURLSessionCache()
                    await ImageDownloader.shared.clearMemoryCache()
                    NotificationCenter.default.post(name: .GravatarQEAvatarUpdateNotification,
                                                    object: self,
                                                    userInfo: [GravatarQEAvatarUpdateNotificationKeys.email.rawValue: email])
                }
            }, onDismiss: {
                // No op.
            }
        )
    }
}
