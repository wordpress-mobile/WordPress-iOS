import UIKit

class SignupEpilogueViewController: NUXViewController {

    // MARK: - Properties

    private var buttonViewController: NUXButtonViewController?
    private var updatedDisplayName: String?
    private var updatedPassword: String?

    // MARK: - View

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
            buttonViewController?.setButtonTitles(primary: NSLocalizedString("Continue", comment: "Button text on site creation epilogue page to proceed to My Sites."))
        }

        if let vc = segue.destination as? SignupEpilogueTableViewController {
            vc.loginFields = loginFields
            vc.delegate = self
        }
    }

}

// MARK: - NUXButtonViewControllerDelegate

extension SignupEpilogueViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        updateUserInfo()
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - SignupEpilogueTableViewControllerDelegate

extension SignupEpilogueViewController: SignupEpilogueTableViewControllerDelegate {
    func displayNameUpdated(newDisplayName: String) {
        updatedDisplayName = newDisplayName
    }

    func passwordUpdated(newPassword: String) {
        updatedPassword = newPassword
    }

}

// MARK: - Private Extension

private extension SignupEpilogueViewController {

    func updateUserInfo() {
        let context = ContextManager.sharedInstance().mainContext
        guard let restApi = AccountService(managedObjectContext: context).defaultWordPressComAccount()?.wordPressComRestApi else {
            return
        }
        let remote = AccountSettingsRemote.remoteWithApi(restApi)

        if let updatedDisplayName = updatedDisplayName {
            let accountSettingsChange = AccountSettingsChange.displayName(updatedDisplayName)
            remote.updateSetting(accountSettingsChange, success: { () in
                self.updatePassword()
            }, failure: { error in
                DDLogError("Error updating user display name: \(error)")
            })
        } else {
            updatePassword()
        }
    }

    func updatePassword() {
        let context = ContextManager.sharedInstance().mainContext
        guard let restApi = AccountService(managedObjectContext: context).defaultWordPressComAccount()?.wordPressComRestApi else {
            return
        }
        let remote = AccountSettingsRemote.remoteWithApi(restApi)

        if let updatedPassword = updatedPassword {
            remote.updatePassword(updatedPassword, success: { () in
            }, failure: { error in
                DDLogError("Error updating user password: \(error)")
            })
        }
    }

}
