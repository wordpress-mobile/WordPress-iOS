import Foundation
import GravatarUI
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
                interfaceStyle: nil
            ),
            token: authToken
        )
        presenter.present(in: presentingViewController, onAvatarUpdated: {
            AuthenticatorAnalyticsTracker.shared.track(click: .selectAvatar)
            NotificationCenter.default.post(name: .GravatarImageUpdateNotification, object: self, userInfo: ["email": email])
        }, onDismiss: {
        })
    }
}
