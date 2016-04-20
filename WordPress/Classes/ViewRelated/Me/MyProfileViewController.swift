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

/// MyProfileController requires the `presenter` to be set before using.
/// To avoid problems, it's marked private and should only be initialized using the
/// `MyProfileViewController` factory functions.
private struct MyProfileController: SettingsController {
    // MARK: - ImmuTableController

    let title = NSLocalizedString("My Profile", comment: "My Profile view title")

    var immuTableRows: [ImmuTableRow.Type] {
        return [EditableTextRow.self]
    }

    // MARK: - Initialization

    let service: AccountSettingsService

    init(service: AccountSettingsService) {
        self.service = service
    }
    
    // MARK: - ImmuTableViewController
    
    func tableViewModelWithPresenter(presenter: ImmuTablePresenter) -> Observable<ImmuTable> {
        return service.settings.map({ settings in
            self.mapViewModel(settings, presenter: presenter)
        })
    }
    
    var errorMessage: Observable<String?> {
        return service.refresh
            // replace errors with .Failed status
            .catchErrorJustReturn(.Failed)
            // convert status to string
            .map({ $0.errorMessage })
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
            action: presenter.push(editText(AccountSettingsChange.AboutMe, service: service)))

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
