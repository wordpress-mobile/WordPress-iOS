import Foundation
import GravatarUI
import WordPressShared
import WordPressAuthenticator

@MainActor
struct GravatarQuickEditorPresenter {
    let email: String
    let authToken: String

    init?(email: String) {
        let context = ContextManager.sharedInstance().mainContext
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
            return nil
        }
        self.email = email
        self.authToken = account.authToken
    }

    func presentQuickEditor(on presentingViewController: UIViewController) {
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
