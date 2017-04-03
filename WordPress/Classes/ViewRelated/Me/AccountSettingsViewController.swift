import Foundation
import UIKit
import WordPressComAnalytics

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
        notificationCenter.addObserver(self, selector: #selector(AccountSettingsController.loadStatus), name: NSNotification.Name(rawValue: AccountSettingsService.Notifications.refreshStatusChanged), object: nil)
        notificationCenter.addObserver(self, selector: #selector(AccountSettingsController.loadSettings), name: NSNotification.Name(rawValue: AccountSettingsService.Notifications.accountSettingsChanged), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        let primarySiteName = settings.flatMap { service.primarySiteNameForSettings($0) }

        let username = TextRow(
            title: NSLocalizedString("Username", comment: "Account Settings Username label"),
            value: settings?.username ?? "")

        let email = EditableTextRow(
            title: NSLocalizedString("Email", comment: "Account Settings Email label"),
            value: settings?.emailForDisplay ?? "",
            action: presenter.push(editEmailAddress(settings, service: service))
        )

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

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                    username,
                    email,
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


    // MARK: - Private Helpers

    fileprivate func noticeForAccountSettings(_ settings: AccountSettings?) -> String? {
        guard let pendingAddress = settings?.emailPendingAddress, settings?.emailPendingChange == true else {
            return nil
        }

        return NSLocalizedString("There is a pending change of your email to \(pendingAddress). Please check your inbox for a confirmation link.",
                                 comment: "Displayed when there's a pending Email Change")
    }
}
