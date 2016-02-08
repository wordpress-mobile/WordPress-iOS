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
    return viewController
}

private struct MyProfileController: ImmuTableController {
    // MARK: - ImmuTableController

    let title = NSLocalizedString("My Profile", comment: "My Profile view title")

    var immuTableRows: [ImmuTableRow.Type] {
        return [EditableTextRow.self]
    }

    func tableViewModelWithPresenter(presenter: ImmuTablePresenter) -> Observable<ImmuTable> {
        return service.settings.map({ settings in
            return self.mapViewModel(settings, presenter: presenter)
        })
    }

    var errorMessage: Observable<String?> {
        return service.refresh
            // replace errors with .Failed status
            .catchErrorJustReturn(.Failed)
            // convert status to string
            .map({ $0.errorMessage })
    }

    // MARK: - Initialization

    let service: AccountSettingsService

    init(service: AccountSettingsService) {
        self.service = service
    }

    // MARK: - Model mapping

    func mapViewModel(settings: AccountSettings?, presenter: ImmuTablePresenter) -> ImmuTable {
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

    // MARK: - Actions

    func editText(changeType: (AccountSettingsChangeWithString), hint: String? = nil) -> ImmuTableRowControllerGenerator {
        return { row in
            let row = row as! EditableTextRow
            return self.controllerForEditableText(row, changeType: changeType, hint: hint)
        }
    }

    func controllerForEditableText(row: EditableTextRow, changeType: (AccountSettingsChangeWithString), hint: String? = nil, isPassword: Bool = false) -> SettingsTextViewController {
        let title = row.title
        let value = row.value

        let controller = SettingsTextViewController(
            text: value,
            placeholder: "\(title)...",
            hint: hint,
            isPassword: isPassword)

        controller.title = title
        controller.onValueChanged = {
            value in

            let change = changeType(value)
            self.service.saveChange(change)
            DDLogSwift.logDebug("\(title) changed: \(value)")
        }

        return controller
    }
}
