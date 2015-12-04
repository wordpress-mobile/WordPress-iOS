import UIKit
import WordPressShared

class MyProfileViewController: UITableViewController {
    var account: WPAccount! {
        didSet {
            self.service = AccountSettingsService(userID: account.userID.integerValue, api: account.restApi)
        }
    }

    var service: AccountSettingsService! {
        didSet {
            subscribeSettings()
        }
    }

    var settingsSubscription: AccountSettingsSubscription?

    var handler: ImmuTableViewHandler!

    // MARK: - Table View Controller

    required convenience init() {
        self.init(style: .Grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("My Profile", comment: "My Profile view title")

        ImmuTable.registerRows([
            EditableTextRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        service.refreshSettings({ _ in })
    }

    override func viewWillAppear(animated: Bool) {
        if settingsSubscription == nil {
            subscribeSettings()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        unsubscribeSettings()
    }

    // MARK: - View Model

    func buildViewModel(settings: AccountSettings?) {
        let firstNameRow = EditableTextRow(
            title: NSLocalizedString("First Name", comment: "My Profile first name label"),
            value: settings?.firstName ?? "",
            action: editableTextRowAction(AccountSettingsChange.FirstName))

        let lastNameRow = EditableTextRow(
            title: NSLocalizedString("Last Name", comment: "My Profile last name label"),
            value: settings?.lastName ?? "",
            action: editableTextRowAction(AccountSettingsChange.LastName))

        let displayNameRow = EditableTextRow(
            title: NSLocalizedString("Display Name", comment: "My Profile display name label"),
            value: settings?.displayName ?? "",
            action: editableTextRowAction(AccountSettingsChange.DisplayName))

        let aboutMeRow = EditableTextRow(
            title: NSLocalizedString("About Me", comment: "My Profile 'About me' label"),
            value: settings?.aboutMe ?? "",
            action: editableTextRowAction(AccountSettingsChange.AboutMe))

        handler.viewModel =  ImmuTable(sections: [
            ImmuTableSection(rows: [
                firstNameRow,
                lastNameRow,
                displayNameRow,
                aboutMeRow
                ])
            ])
    }

    func subscribeSettings() {
        settingsSubscription = service.subscribeSettings({
            [unowned self]
            (settings) -> Void in

            DDLogSwift.logDebug("Got settings \(settings)")
            self.buildViewModel(settings)
        })
    }

    func unsubscribeSettings() {
        settingsSubscription = nil
    }

    // MARK: - Cell Actions

    func editableTextRowAction(changeType: String -> AccountSettingsChange) -> (ImmuTableRow) -> Void {
        return {
            [unowned self]
            row in

            let row = row as! EditableTextRow
            let controller = self.controllerForEditableText(row, changeType: changeType)

            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func controllerForEditableText(row: EditableTextRow, changeType: String -> AccountSettingsChange) -> SettingsTextViewController {
        let title = row.title
        let value = row.value

        let controller = SettingsTextViewController(
            text: value,
            placeholder: "\(title)...",
            hint: nil,
            isPassword: false)

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
