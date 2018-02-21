import UIKit

class SignupEpilogueViewController: NUXViewController {

    // MARK: - Properties

    private var buttonViewController: NUXButtonViewController?
    private var updatedDisplayName: String?

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

    // MARK: - Update User Settings

    private func updateDisplayName() {

        guard let updatedDisplayName = updatedDisplayName else {
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        guard let restApi = AccountService(managedObjectContext: context).defaultWordPressComAccount()?.wordPressComRestApi else {
            return
        }
        let remote = AccountSettingsRemote.remoteWithApi(restApi)

        let accountSettingsChange = AccountSettingsChange.displayName(updatedDisplayName)
        remote.updateSetting(accountSettingsChange, success: { () in
        }, failure: { error in
            DDLogError("Error updating user display name: \(error)")
        })
    }

}

// MARK: - NUXButtonViewControllerDelegate

extension SignupEpilogueViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        updateDisplayName()
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - SignupEpilogueTableViewControllerDelegate

extension SignupEpilogueViewController: SignupEpilogueTableViewControllerDelegate {
    func displayNameUpdated(newDisplayName: String) {
        updatedDisplayName = newDisplayName
    }
}
