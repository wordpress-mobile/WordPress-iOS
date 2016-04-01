import RxSwift

protocol SettingsController: ImmuTableController {}

// MARK: - Actions
extension SettingsController {
    func editText(changeType: AccountSettingsChangeWithString,
                  hint: String? = nil,
                  isEmail: Bool = false,
                  isPassword: Bool = false,
                  service: AccountSettingsService) -> ImmuTableRowControllerGenerator
    {
        return { row in
            return self.controllerForEditableText(row as! EditableTextRow,
                                                  changeType: changeType,
                                                  hint: hint,
                                                  isEmail: isEmail,
                                                  isPassword: isPassword,
                                                  service: service)
        }
    }

    func controllerForEditableText(row: EditableTextRow,
                                   changeType: AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   isEmail: Bool = false,
                                   isPassword: Bool = false,
                                   service: AccountSettingsService) -> SettingsTextViewController
    {
        let title = row.title
        let value = row.value

        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.isEmail = isEmail
        controller.isPassword = isPassword
        controller.onValueChanged = {
            value in

            let change = changeType(value)
            service.saveChange(change)
            DDLogSwift.logDebug("\(title) changed: \(value)")
        }

        return controller
    }
}