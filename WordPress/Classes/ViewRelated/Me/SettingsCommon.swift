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
        let title = row.title
        let value = row.value

        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.onValueChanged = {
            value in

            let change = changeType(value)
            service.saveChange(change)
            DDLogSwift.logDebug("\(title) changed: \(value)")
        }

        return controller
    }

    func controllerForEditableMultilineText(row: EditableTextRow,
                                   changeType: AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   service: AccountSettingsService) -> SettingsMultiTextViewController
    {
        let title = row.title
        let value = row.value

        let controller = SettingsMultiTextViewController(text: value, placeholder: "\(title)...", hint: hint, isPassword: false)

        controller.title = title
        controller.onValueChanged = {
            value in

            let change = changeType(value)
            service.saveChange(change)
            DDLogSwift.logDebug("\(title) changed: \(value)")
        }

        return controller
    }
}
