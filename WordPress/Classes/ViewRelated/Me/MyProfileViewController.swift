import UIKit
import RxSwift
import WordPressShared

class MyProfileController: NSObject {
    let title = NSLocalizedString("My Profile", comment: "My Profile view title")
    let service: AccountSettingsService
    let viewController = ImmuTableViewController()

    init(service: AccountSettingsService) {
        self.service = service
        super.init()

        viewController.title = title
        viewController.registerRows(immutableRows)

        _ = viewModel
            .observeOn(MainScheduler.instance)
            .takeUntil(viewController.rx_deallocated)
            .subscribeNext(viewController.bindViewModel)
        // Only refresh on first appearance
        _ = viewController.willAppear.take(1).subscribeNext {
            service.refreshSettings({ _ in })
        }
    }

    convenience init(account: WPAccount) {
        self.init(service: AccountSettingsService(userID: account.userID.integerValue, api: account.restApi))
    }

    var immutableRows: [ImmuTableRow.Type] {
        return [EditableTextRow.self]
    }

    var viewModel: Observable<ImmuTable> {
        return service.settingsObserver.map(mapViewModel)
    }

    func mapViewModel(settings: AccountSettings?) -> ImmuTable {
        let firstNameRow = EditableTextRow(
            title: NSLocalizedString("First Name", comment: "My Profile first name label"),
            value: settings?.firstName ?? "",
            action: viewController.push(editText(AccountSettingsChange.FirstName)))

        let lastNameRow = EditableTextRow(
            title: NSLocalizedString("Last Name", comment: "My Profile last name label"),
            value: settings?.lastName ?? "",
            action: viewController.push(editText(AccountSettingsChange.LastName)))

        let displayNameRow = EditableTextRow(
            title: NSLocalizedString("Display Name", comment: "My Profile display name label"),
            value: settings?.displayName ?? "",
            action: viewController.push(editText(AccountSettingsChange.DisplayName)))

        let aboutMeRow = EditableTextRow(
            title: NSLocalizedString("About Me", comment: "My Profile 'About me' label"),
            value: settings?.aboutMe ?? "",
            action: viewController.push(editText(AccountSettingsChange.AboutMe)))

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                firstNameRow,
                lastNameRow,
                displayNameRow,
                aboutMeRow
                ])
            ])
    }

    func editText(changeType: (AccountSettingsChangeWithString), hint: String? = nil) -> ImmuTableRowControllerGenerator {
        return { [unowned self] row in
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
            [unowned self]
            value in

            let change = changeType(value)
            self.service.saveChange(change)
            DDLogSwift.logDebug("\(title) changed: \(value)")
        }

        return controller
    }
}
