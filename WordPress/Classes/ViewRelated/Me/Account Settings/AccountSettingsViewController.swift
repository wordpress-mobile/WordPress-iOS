import Foundation
import UIKit
import WordPressShared
import WordPressFlux

func AccountSettingsViewController(account: WPAccount) -> ImmuTableViewController? {
    guard let api = account.wordPressComRestApi else {
        return nil
    }
    let service = AccountSettingsService(userID: account.userID.intValue, api: api)
    return AccountSettingsViewController(service: service)
}

func AccountSettingsViewController(service: AccountSettingsService) -> ImmuTableViewController {
    let controller = AccountSettingsController(service: service)
    let viewController = ImmuTableViewController(controller: controller)
    viewController.handler.automaticallyDeselectCells = true
    return viewController
}

private class AccountSettingsController: SettingsController {
    let title = NSLocalizedString("Account Settings", comment: "Account Settings Title")

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            TextRow.self,
            EditableTextRow.self,
            DestructiveButtonRow.self
        ]
    }


    // MARK: - Initialization

    let service: AccountSettingsService
    var settings: AccountSettings? {
        didSet {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ImmuTableViewController.modelChangedNotification), object: nil)
        }
    }
    var noticeMessage: String? {
        didSet {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ImmuTableViewController.modelChangedNotification), object: nil)
        }
    }
    private let alertHelper = DestructiveAlertHelper()

    init(service: AccountSettingsService) {
        self.service = service
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AccountSettingsController.loadStatus), name: NSNotification.Name.AccountSettingsServiceRefreshStatusChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AccountSettingsController.loadSettings), name: NSNotification.Name.AccountSettingsChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AccountSettingsController.showSettingsChangeErrorMessage), name: NSNotification.Name.AccountSettingsServiceChangeSaveFailed, object: nil)
    }

    func refreshModel() {
        service.refreshSettings()
    }

    @objc func loadStatus() {
        noticeMessage = service.status.errorMessage ?? noticeForAccountSettings(service.settings)
    }

    @objc func loadSettings() {
        settings = service.settings
        // Status is affected by settings changes (for pending email), so let's load that as well
        loadStatus()
    }


    // MARK: - ImmuTableViewController

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter) -> ImmuTable {
        return mapViewModel(settings, service: service, presenter: presenter)
    }


    // MARK: - Model mapping

    func mapViewModel(_ settings: AccountSettings?, service: AccountSettingsService, presenter: ImmuTablePresenter) -> ImmuTable {

        let username = TextRow(
            title: NSLocalizedString("Username", comment: "Account Settings Username label"),
            value: settings?.username ?? ""
        )

        let editableUsername = EditableTextRow(
            title: NSLocalizedString("Username", comment: "Account Settings Username label"),
            value: settings?.username ?? "",
            action: presenter.push(changeUsername(with: settings, service: service))
        )

        let email = EditableTextRow(
            title: NSLocalizedString("Email", comment: "Account Settings Email label"),
            value: settings?.emailForDisplay ?? "",
            accessoryImage: emailAccessoryImage(),
            action: presenter.push(editEmailAddress(settings, service: service))
        )

        var primarySiteName = settings.flatMap { service.primarySiteNameForSettings($0) } ?? ""

        // If the primary site has no Site Title, then show the displayURL.
        if primarySiteName.isEmpty {
            let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            primarySiteName = blogService.primaryBlog()?.displayURL as String? ?? ""
        }

        let primarySite = EditableTextRow(
            title: NSLocalizedString("Primary Site", comment: "Primary Web Site"),
            value: primarySiteName,
            action: presenter.present(insideNavigationController(editPrimarySite(settings, service: service)))
        )

        let webAddress = EditableTextRow(
            title: NSLocalizedString("Web Address", comment: "Account Settings Web Address label"),
            value: settings?.webAddress ?? "",
            action: presenter.push(editWebAddress(service))
        )

        let password = EditableTextRow(
            title: Constants.title,
            value: "",
            action: presenter.push(changePassword(with: settings, service: service))
        )

        let closeAccount = DestructiveButtonRow(
            title: NSLocalizedString("Close Account", comment: "Close account action label"),
            action: presenter.present(closeAccountAction),
            accessibilityIdentifier: "closeAccountButtonRow")

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    (settings?.usernameCanBeChanged ?? false) ? editableUsername : username,
                    email,
                    password,
                    primarySite,
                    webAddress
                ]),
            ImmuTableSection(
                rows: [
                    closeAccount
                ])
        ])
    }

    // MARK: - Actions

    func editEmailAddress(_ settings: AccountSettings?, service: AccountSettingsService) -> (ImmuTableRow) -> SettingsTextViewController {
        return { row in
            let editableRow = row as! EditableTextRow
            let hint = NSLocalizedString("Will not be publicly displayed.", comment: "Help text when editing email address")
            let settingsViewController =  self.controllerForEditableText(editableRow,
                                                                         changeType: AccountSettingsChange.email,
                                                                         hint: hint,
                                                                         service: service)
            settingsViewController.mode = .email
            settingsViewController.notice = self.noticeForAccountSettings(settings)
            settingsViewController.displaysActionButton = settings?.emailPendingChange ?? false
            settingsViewController.actionText = NSLocalizedString("Revert Pending Change", comment: "Cancels a pending Email Change")
            settingsViewController.onActionPress = {
                service.saveChange(.emailRevertPendingChange)
            }

            return settingsViewController
        }
    }

    func changePassword(with settings: AccountSettings?, service: AccountSettingsService) -> (ImmuTableRow) -> SettingsTextViewController {
        return { row in
            return ChangePasswordViewController(username: settings?.username ?? "") { [weak self] value in
                DispatchQueue.main.async {
                    SVProgressHUD.show(withStatus: Constants.changingPassword)
                    service.updatePassword(value, finished: { (success, error) in
                        if success {
                            self?.refreshAccountDetails {
                                SVProgressHUD.showSuccess(withStatus: Constants.changedPasswordSuccess)
                            }
                        } else {
                            let errorMessage = error?.localizedDescription ?? Constants.changePasswordGenericError
                            SVProgressHUD.showError(withStatus: errorMessage)
                        }
                    })
                }
            }
        }
    }

    func changeUsername(with settings: AccountSettings?, service: AccountSettingsService) -> (ImmuTableRow) -> ChangeUsernameViewController {
        return { _ in
            return ChangeUsernameViewController(service: service, settings: settings) { [weak self] username in
                self?.refreshModel()
                if let username = username {
                    let notice = Notice(title: String(format: Constants.usernameChanged, username))
                    ActionDispatcher.dispatch(NoticeAction.post(notice))
                }
            }
        }
    }

    func refreshAccountDetails(finished: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return
        }
        service.updateUserDetails(for: account, success: { () in
            finished()
        }, failure: { _ in
            finished()
        })
    }

    func editWebAddress(_ service: AccountSettingsService) -> (ImmuTableRow) -> SettingsTextViewController {
        let hint = NSLocalizedString("Shown publicly when you comment on blogs.", comment: "Help text when editing web address")
        return editText(AccountSettingsChange.webAddress, hint: hint, service: service)
    }

    func editPrimarySite(_ settings: AccountSettings?, service: AccountSettingsService) -> ImmuTableRowControllerGenerator {
        return {
            row in

            let selectorViewController = BlogSelectorViewController(selectedBlogDotComID: settings?.primarySiteID as NSNumber?,
                                                                    successHandler: { (dotComID: NSNumber?) in
                                                                        if let dotComID = dotComID?.intValue {
                                                                            let change = AccountSettingsChange.primarySite(dotComID)
                                                                            service.saveChange(change)
                                                                        }
            },
                                                                    dismissHandler: nil)

            selectorViewController.title = NSLocalizedString("Primary Site", comment: "Primary Site Picker's Title")
            selectorViewController.displaysOnlyDefaultAccountSites = true
            selectorViewController.displaysCancelButton = true
            selectorViewController.dismissOnCompletion = true
            selectorViewController.dismissOnCancellation = true

            return selectorViewController
        }
    }

    private var closeAccountAction: (ImmuTableRow) -> UIAlertController {
        return { [weak self] _ in
            return self?.closeAccountAlert ?? UIAlertController()
        }
    }

    private var closeAccountAlert: UIAlertController? {
        guard let value = settings?.username else {
            return nil
        }

        let title = NSLocalizedString("Confirm Close Account", comment: "Close Account alert title")
        let message = NSLocalizedString("\nTo confirm, please re-enter your username before closing.\n\n",
                                        comment: "Message of Close Account confirmation alert")
        let destructiveActionTitle = NSLocalizedString("Permanently Close Account",
                                                       comment: "Close Account confirmation action title")

        return alertHelper.makeAlertWithConfirmation(title: title, message: message, valueToConfirm: value, destructiveActionTitle: destructiveActionTitle, destructiveAction: closeAccount)
    }

    private func closeAccount() {
        let status = NSLocalizedString("Closing account…", comment: "Overlay message displayed while closing account")
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.show(withStatus: status)

        service.closeAccount { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success:
                let status = NSLocalizedString("Account closed", comment: "Overlay message displayed when account successfully closed")
                SVProgressHUD.showDismissibleSuccess(withStatus: status)
                AccountHelper.logOutDefaultWordPressComAccount()
            case .failure(let error):
                SVProgressHUD.dismiss()
                DDLogError("Error closing account: \(error.localizedDescription)")
                self.showErrorAlert(message: self.generateLocalizedMessage(error))
            }
        }
    }

    private func generateLocalizedMessage(_ error: Error) -> String {
        let userInfo = (error as NSError).userInfo
        let errorCode = userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String

        switch errorCode {
        case "unauthorized":
            return NSLocalizedString("You're not authorized to close the account.",
                                     comment: "Error message displayed when unable to close user account due to being unauthorized.")
        case "atomic-site":
            return NSLocalizedString("This user account cannot be closed while it has active atomic sites.",
                                     comment: "Error message displayed when unable to close user account due to having active atomic site.")
        case "chargebacked-site":
            return NSLocalizedString("This user account cannot be closed if there are unresolved chargebacks.",
                                     comment: "Error message displayed when unable to close user account due to unresolved chargebacks.")
        case "active-subscriptions":
            return NSLocalizedString("This user account cannot be closed while it has active subscriptions.",
                                     comment: "Error message displayed when unable to close user account due to having active subscriptions.")
        case "active-memberships":
            return NSLocalizedString("This user account cannot be closed while it has active purchases.",
                                     comment: "Error message displayed when unable to close user account due to having active purchases.")
        default:
            return NSLocalizedString("An error occured while closing account.",
                                     comment: "Default error message displayed when unable to close user account.")
        }
    }

    private func showErrorAlert(message: String) {
        let title = NSLocalizedString("Error", comment: "General error title")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = NSLocalizedString("OK", comment: "Alert dismissal title")
        alert.addDefaultActionWithTitle(okAction, handler: nil)
        alert.presentFromRootViewController()
    }

    @objc fileprivate func showSettingsChangeErrorMessage(notification: NSNotification) {
        guard let error = notification.userInfo?[NSUnderlyingErrorKey] as? NSError,
            let errorMessage = error.userInfo[WordPressComRestApi.ErrorKeyErrorMessage] as? String else {
                return
        }
        SVProgressHUD.showError(withStatus: errorMessage)
    }

    // MARK: - Private Helpers

    fileprivate func noticeForAccountSettings(_ settings: AccountSettings?) -> String? {
        guard settings?.emailPendingChange == true,
              let pendingAddress = settings?.emailPendingAddress else {
            return nil
        }

        let localizedNotice = NSLocalizedString("There is a pending change of your email to %@. Please check your inbox for a confirmation link.",
            comment: "Displayed when there's a pending Email Change. The variable is the new email address.")

        return String(format: localizedNotice, pendingAddress)
    }

    fileprivate func emailAccessoryImage() -> UIImage? {
        guard settings?.emailPendingChange == true else {
            return nil
        }

        return UIImage.gridicon(.noticeOutline).imageWithTintColor(.error)
    }

    // MARK: - Constants

    enum Constants {
        static let title = NSLocalizedString("Change Password", comment: "Account Settings Change password label")
        static let changingPassword = NSLocalizedString("Changing password", comment: "Loader title displayed by the loading view while the password is changing")
        static let changedPasswordSuccess = NSLocalizedString("Password changed successfully", comment: "Loader title displayed by the loading view while the password is changed successfully")
        static let changePasswordGenericError = NSLocalizedString("There was an error changing the password", comment: "Text displayed when there is a failure loading the history.")
        static let usernameChanged = NSLocalizedString("Username changed to %@", comment: "Message displayed in a Notice when the username has changed successfully. The placeholder is the new username.")
    }
}
