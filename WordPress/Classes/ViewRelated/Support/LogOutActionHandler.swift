import UIKit

struct LogOutActionHandler {

    private weak var windowManager: WindowManager?

    init(windowManager: WindowManager? = WordPressAppDelegate.shared?.windowManager) {
        self.windowManager = windowManager
    }

    func logOut(with viewController: UIViewController) {
        let alert  = UIAlertController(title: logOutAlertTitle, message: nil, preferredStyle: .alert)
        alert.addActionWithTitle(Strings.alertCancelAction, style: .cancel)
        alert.addActionWithTitle(Strings.alertLogoutAction, style: .destructive) { [weak viewController] _ in
            viewController?.dismiss(animated: true) {
                AccountHelper.logOutDefaultWordPressComAccount()
                windowManager?.showSignInUI()
            }
        }
        viewController.present(alert, animated: true)
    }

    private var logOutAlertTitle: String {
        let context = ContextManager.sharedInstance().mainContext
        let count = AbstractPost.countLocalPosts(in: context)

        guard count > 0 else {
            return Strings.alertDefaultTitle
        }

        let format = count > 1 ? Strings.alertUnsavedTitlePlural : Strings.alertUnsavedTitleSingular
        return String(format: format, count)
    }

    private struct Strings {
        static let alertDefaultTitle = AppConstants.Logout.alertTitle
        static let alertUnsavedTitleSingular = NSLocalizedString("You have changes to %d post that hasn't been uploaded to your site. Logging out now will delete those changes. Log out anyway?",
                                                            comment: "Warning displayed before logging out. The %d placeholder will contain the number of local posts (SINGULAR!)")
        static let alertUnsavedTitlePlural = NSLocalizedString("You have changes to %d posts that haven’t been uploaded to your site. Logging out now will delete those changes. Log out anyway?",
                                                          comment: "Warning displayed before logging out. The %d placeholder will contain the number of local posts (PLURAL!)")
        static let alertCancelAction = NSLocalizedString("Cancel", comment: "Verb. A button title. Tapping cancels an action.")
        static let alertLogoutAction = NSLocalizedString("Log Out", comment: "Button for confirming logging out from WordPress.com account")
    }
}
