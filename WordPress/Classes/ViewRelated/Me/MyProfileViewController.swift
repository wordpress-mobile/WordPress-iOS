import UIKit
import RxSwift
import WordPressShared

func MyProfileViewController(account account: WPAccount) -> ImmuTableViewController {
    let service = AccountSettingsService(userID: account.userID.integerValue, api: account.restApi)
    return MyProfileViewController(service: service)
}

func MyProfileViewController(service service: AccountSettingsService) -> ImmuTableViewController {
    let controller = MyProfileController(service: service)
    let viewController = ImmuTableViewController(controller: controller)
    assert(viewController.controller?.presenter != nil, "ImmuTableViewController should have set the presenter for MyProfileController")
    return viewController
}

/// MyProfileController requires the `presenter` to be set before using.
/// To avoid problems, it's marked private and should only be initialized using the
/// `MyProfileViewController` factory functions.
private struct MyProfileController: SettingsController {
    // MARK: - ImmuTableController

    weak var presenter: ImmuTablePresenter? = nil

    let title = NSLocalizedString("My Profile", comment: "My Profile view title")

    var immuTableRows: [ImmuTableRow.Type] {
        return [EditableTextRow.self]
    }

    // MARK: - Initialization

    let service: AccountSettingsService

    init(service: AccountSettingsService) {
        self.service = service
    }

    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?) -> ImmuTable {
        precondition(presenter != nil, "presenter must be set before using")
        guard let presenter = presenter else {
            // This shouldn't happen. If there's no presenter we can't push the
            // editText controllers.
            return ImmuTable.Empty
        }
        let firstNameRow = EditableTextRow(
            title: NSLocalizedString("First Name", comment: "My Profile first name label"),
            value: settings?.firstName ?? "",
            action: presenter.push(editText(AccountSettingsChange.FirstName)))

        let lastNameRow = EditableTextRow(
            title: NSLocalizedString("Last Name", comment: "My Profile last name label"),
            value: settings?.lastName ?? "",
            action: presenter.push(editText(AccountSettingsChange.LastName)))

        let displayNameRow = EditableTextRow(
            title: NSLocalizedString("Display Name", comment: "My Profile display name label"),
            value: settings?.displayName ?? "",
            action: presenter.push(editText(AccountSettingsChange.DisplayName)))

        let aboutMeRow = EditableTextRow(
            title: NSLocalizedString("About Me", comment: "My Profile 'About me' label"),
            value: settings?.aboutMe ?? "",
            action: presenter.push(editText(AccountSettingsChange.AboutMe)))

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
