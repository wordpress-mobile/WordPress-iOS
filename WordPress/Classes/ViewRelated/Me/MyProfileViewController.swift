import UIKit
import WordPressShared

func MyProfileViewController(account account: WPAccount) -> ImmuTableViewController? {
    guard let api = account.restApi else {
        return nil
    }

    let service = AccountSettingsService(userID: account.userID.integerValue, api: api)
    return MyProfileViewController(service: service)
}

func MyProfileViewController(service service: AccountSettingsService) -> ImmuTableViewController {
    let controller = MyProfileController(service: service)
    let viewController = ImmuTableViewController(controller: controller)
    return viewController
}

/// MyProfileController requires the `presenter` to be set before using.
/// To avoid problems, it's marked private and should only be initialized using the
/// `MyProfileViewController` factory functions.
private class MyProfileController: SettingsController {
    // MARK: - ImmuTableController

    let title = NSLocalizedString("My Profile", comment: "My Profile view title")

    var immuTableRows: [ImmuTableRow.Type] {
        return [EditableTextRow.self]
    }

    // MARK: - Initialization

    let service: AccountSettingsService
    var settings: AccountSettings? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(ImmuTableViewController.modelChangedNotification, object: nil)
        }
    }
    var noticeMessage: String? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(ImmuTableViewController.modelChangedNotification, object: nil)
        }
    }

    init(service: AccountSettingsService) {
        self.service = service
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(MyProfileController.loadStatus), name: AccountSettingsService.Notifications.refreshStatusChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MyProfileController.loadSettings), name: AccountSettingsService.Notifications.accountSettingsChanged, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func refreshModel() {
        service.refreshSettings()
    }

    @objc func loadStatus() {
        noticeMessage = service.status.errorMessage
    }

    @objc func loadSettings() {
        settings = service.settings
    }

    // MARK: - ImmuTableViewController

    func tableViewModelWithPresenter(presenter: ImmuTablePresenter) -> ImmuTable {
        return mapViewModel(settings, presenter: presenter)
    }

    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?, presenter: ImmuTablePresenter) -> ImmuTable {
        let firstNameRow = EditableTextRow(
            title: NSLocalizedString("First Name", comment: "My Profile first name label"),
            value: settings?.firstName ?? "",
            action: presenter.push(editText(AccountSettingsChange.FirstName, service: service)))

        let lastNameRow = EditableTextRow(
            title: NSLocalizedString("Last Name", comment: "My Profile last name label"),
            value: settings?.lastName ?? "",
            action: presenter.push(editText(AccountSettingsChange.LastName, service: service)))

        let displayNameRow = EditableTextRow(
            title: NSLocalizedString("Display Name", comment: "My Profile display name label"),
            value: settings?.displayName ?? "",
            action: presenter.push(editText(AccountSettingsChange.DisplayName, service: service)))

        let aboutMeRow = EditableTextRow(
            title: NSLocalizedString("About Me", comment: "My Profile 'About me' label"),
            value: settings?.aboutMe ?? "",
            action: presenter.push(editMultilineText(AccountSettingsChange.AboutMe,
                hint:NSLocalizedString("Tell us a bit about you.", comment: "My Profile 'About me' hint text"),
                service: service)))

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                firstNameRow,
                lastNameRow,
                displayNameRow,
                aboutMeRow
                ])
            ])
    }

}
