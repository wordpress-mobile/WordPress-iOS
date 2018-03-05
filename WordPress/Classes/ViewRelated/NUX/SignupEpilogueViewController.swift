import SVProgressHUD

class SignupEpilogueViewController: NUXViewController {

    // MARK: - Properties

    private var buttonViewController: NUXButtonViewController?
    private var updatedDisplayName: String?
    private var updatedPassword: String?
    private var updatedUsername: String?
    private var epilogueUserInfo: LoginEpilogueUserInfo?

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
            vc.dataSource = self
            vc.delegate = self
        }

        if let vc = segue.destination as? SignupUsernameViewController {
            vc.currentUsername = epilogueUserInfo?.username
            vc.displayName = updatedDisplayName ?? epilogueUserInfo?.fullName
            vc.delegate = self
        }
    }

}

// MARK: - NUXButtonViewControllerDelegate

extension SignupEpilogueViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        saveChanges()
    }
}

// MARK: - SignupEpilogueTableViewControllerDataSource

extension SignupEpilogueViewController: SignupEpilogueTableViewControllerDataSource {
    var customDisplayName: String? {
        return updatedDisplayName
    }

    var password: String? {
        return updatedPassword
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

    func usernameTapped(userInfo: LoginEpilogueUserInfo?) {
        epilogueUserInfo = userInfo
        performSegue(withIdentifier: .showUsernames, sender: self)
    }
}

// MARK: - Private Extension

private extension SignupEpilogueViewController {
    func saveChanges() {
        if let newUsername = updatedUsername {
            SVProgressHUD.show(withStatus: NSLocalizedString("Changing username", comment: "Shown while the app waits for the username changing web service to return."))
            changeUsername(to: newUsername) {
                self.updatedUsername = nil
                self.saveChanges()
            }
        } else if let newDisplayName = updatedDisplayName {
            SVProgressHUD.show(withStatus: NSLocalizedString("Changing display name", comment: "Shown while the app waits for the display name changing web service to return."))
            changeDisplayName(to: newDisplayName) {
                self.updatedDisplayName = nil
                self.saveChanges()
            }
        } else if let newPassword = updatedPassword {
            SVProgressHUD.show(withStatus: NSLocalizedString("Changing password", comment: "Shown while the app waits for the password changing web service to return."))
            changePassword(to: newPassword) {
                self.updatedPassword = nil
                self.saveChanges()
            }
        } else {
            self.refreshAccountDetails() {
                SVProgressHUD.dismiss()
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func changeUsername(to newUsername: String, finished: @escaping (() -> Void)) {
        guard newUsername != "" else {
            finished()
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.defaultWordPressComAccount(),
            let api = account.wordPressComRestApi else {
                navigationController?.popViewController(animated: true)
                return
        }

        let settingsService = AccountSettingsService(userID: account.userID.intValue, api: api)
        settingsService.changeUsername(to: newUsername, success: { [weak self] in
            // now we refresh the account to get the new username
//            accountService.updateUserDetails(for: account, success: { [weak self] in
//                    finished()
//                }, failure: { [weak self] (error) in
//                    finished()
//            })
            finished()
        }) { [weak self] in
            finished()
        }
    }

    func changeDisplayName(to newDisplayName: String, finished: @escaping (() -> Void)) {

        let context = ContextManager.sharedInstance().mainContext

        guard let defaultAccount = AccountService(managedObjectContext: context).defaultWordPressComAccount(),
        let restApi = defaultAccount.wordPressComRestApi else {
            finished()
            return
        }

        let accountSettingService = AccountSettingsService(userID: defaultAccount.userID.intValue, api: restApi)
        let accountSettingsChange = AccountSettingsChange.displayName(newDisplayName)

        accountSettingService.saveChange(accountSettingsChange) {
            finished()
            // If the password needs updating, do that.
            // If not, refresh the account so 'Me' tab info is correct.
//            if let _ = self.updatedPassword {
//                self.updatePassword()
//            } else {
//                self.refreshAccountDetails()
//            }
        }
    }

    func changePassword(to newPassword: String, finished: @escaping () -> Void) {

        let context = ContextManager.sharedInstance().mainContext

        guard let defaultAccount = AccountService(managedObjectContext: context).defaultWordPressComAccount(),
            let restApi = defaultAccount.wordPressComRestApi else {
                finished()
                return
        }

        let accountSettingService = AccountSettingsService(userID: defaultAccount.userID.intValue, api: restApi)

        accountSettingService.updatePassword(newPassword) {
            finished()
        }
    }

    func refreshAccountDetails(finished: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            self.navigationController?.dismiss(animated: true, completion: nil)
            return
        }
        service.updateUserDetails(for: account, success: { () in
            finished()
        }, failure: { _ in
            finished()
        })
    }

}

extension SignupEpilogueViewController: SignupUsernameViewControllerDelegate {
    func usernameSelected(_ username: String) {
        if !username.isEmpty {
            updatedUsername = username
        } else {
            updatedUsername = nil
        }
    }
}
