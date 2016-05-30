import UIKit

protocol SettingsController: ImmuTableController {}

// MARK: - Actions
extension SettingsController {
    func insideNavigationController(generator: ImmuTableRowControllerGenerator) -> ImmuTableRowControllerGenerator {
        return { row in
            let controller = generator(row)
            let navigation = UINavigationController(rootViewController: controller)
            navigation.modalPresentationStyle = .FormSheet
            return navigation
        }
    }

    func editText(changeType: AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> ImmuTableRow -> SettingsTextViewController
    {
        return { row in
            let editableRow = row as! EditableTextRow
            return self.controllerForEditableText(editableRow, changeType: changeType, hint: hint, service: service)
        }
    }

    func editMultilineText(changeType: AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> ImmuTableRow -> SettingsMultiTextViewController
    {
        return { row in
            let editableRow = row as! EditableTextRow
            return self.controllerForEditableMultilineText(editableRow, changeType: changeType, hint: hint, service: service)
        }
    }

    func editEmailAddress(changeType: AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> ImmuTableRow -> SettingsTextViewController
    {
        return { row in
            let editableRow = row as! EditableTextRow
            let settingsViewController =  self.controllerForEditableText(editableRow, changeType: changeType, hint: hint, service: service)
            settingsViewController.mode = .Email

            return settingsViewController
        }
    }

    func controllerForEditableText(row: EditableTextRow,
                                   changeType: AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   service: AccountSettingsService) -> SettingsTextViewController
    {
        let controller = SettingsTextViewController(style: .Grouped)

        controller.title = row.title
        controller.text = row.value
        controller.placeholder = "\(title)..."
        controller.hint = hint
        controller.onValueChanged = { value in

            let change = changeType(value)
            service.saveChange(change)
            DDLogSwift.logDebug("\(row.title) changed: \(value)")
        }

        return controller
    }

    func controllerForEditableMultilineText(row: EditableTextRow,
                                   changeType: AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   service: AccountSettingsService) -> SettingsMultiTextViewController
    {
        let controller = SettingsMultiTextViewController(style: .Grouped)

        controller.title = row.title
        controller.text = row.value
        controller.placeholder = "\(title)..."
        controller.hint = hint
        controller.onValueChanged = { value in

            let change = changeType(value)
            service.saveChange(change)
            DDLogSwift.logDebug("\(row.title) changed: \(value)")
        }

        return controller
    }
}
