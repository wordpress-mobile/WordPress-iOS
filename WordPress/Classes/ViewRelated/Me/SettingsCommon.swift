import RxSwift

protocol SettingsController: ImmuTableController {}

// MARK: - Actions
extension SettingsController {
    func editText(changeType: AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> ImmuTableRowControllerGenerator
    {
        return { row in
            let editableRow = row as! EditableTextRow
            return self.controllerForEditableText(editableRow, changeType: changeType, hint: hint, service: service)
        }
    }

    func editEmailAddress(changeType: AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> ImmuTableRowControllerGenerator
    {
        return { row in
            let editableRow = row as! EditableTextRow
            return self.controllerForEditableText(editableRow, changeType: changeType, hint: hint, isEmail: true, service: service)
        }
    }
    
    func controllerForEditableText(row: EditableTextRow,
                                   changeType: AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   isEmail: Bool = false,
                                   service: AccountSettingsService) -> SettingsTextViewController
    {
        let title = row.title
        let value = row.value

        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.isEmail = isEmail
        controller.onValueChanged = {
            value in

            let change = changeType(value)
            service.saveChange(change)
            DDLogSwift.logDebug("\(title) changed: \(value)")
        }

        return controller
    }
}