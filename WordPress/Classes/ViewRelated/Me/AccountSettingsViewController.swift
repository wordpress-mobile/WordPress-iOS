import Foundation
import UIKit
import WordPressShared


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
    return viewController
}

private class AccountSettingsController: SettingsController {
    let title = NSLocalizedString("Account Settings", comment: "Account Settings Title")

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            TextRow.self,
            EditableTextRow.self
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

        let email = EditableTextRow(
            title: NSLocalizedString("Email", comment: "Account Settings Email label"),
            value: settings?.emailForDisplay ?? "",
            action: presenter.push(editEmailAddress(settings, service: service))
        )

        // If the primary site has no name, then show the URL.
        var primarySiteName = settings.flatMap { service.primarySiteNameForSettings($0) }
        primarySiteName = (primarySiteName?.isEmpty ?? true) ? settings?.webAddress : primarySiteName

        let primarySite = EditableTextRow(
            title: NSLocalizedString("Primary Site", comment: "Primary Web Site"),
            value: primarySiteName ?? "",
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

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    username,
                    email,
                    password,
                    primarySite,
                    webAddress
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

    @objc fileprivate func showSettingsChangeErrorMessage(notification: NSNotification) {
        guard let error = notification.userInfo?[NSUnderlyingErrorKey] as? NSError,
            let errorMessage = error.userInfo[WordPressComRestApi.ErrorKeyErrorMessage] as? String else {
                return
        }
        SVProgressHUD.showError(withStatus: errorMessage)
    }

    // MARK: - Private Helpers

    fileprivate func noticeForAccountSettings(_ settings: AccountSettings?) -> String? {
        guard let pendingAddress = settings?.emailPendingAddress, settings?.emailPendingChange == true else {
            return nil
        }

        let localizedNotice = NSLocalizedString("There is a pending change of your email to %@. Please check your inbox for a confirmation link.",
            comment: "Displayed when there's a pending Email Change. The variable is the new email address.")

        return String(format: localizedNotice, pendingAddress)
    }


    // MARK: - Constants

    enum Constants {
        static let title = NSLocalizedString("Change Password", comment: "Account Settings Change password label")
        static let changingPassword = NSLocalizedString("Changing password", comment: "Loader title displayed by the loading view while the password is changing")
        static let changedPasswordSuccess = NSLocalizedString("Password changed successfully", comment: "Loader title displayed by the loading view while the password is changed successfully")
        static let changePasswordGenericError = NSLocalizedString("There was an error changing the password", comment: "Text displayed when there is a failure loading the history.")
    }
}
