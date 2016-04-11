import RxSwift

protocol SettingsController: ImmuTableController {}

// MARK: - Actions
extension SettingsController {
    func insideNavigationController(generator: ImmuTableRowControllerGenerator) -> ImmuTableRowControllerGenerator {
        return { row in
            let controller = generator(row)
            let navigation = UINavigationController(rootViewController: controller)
            return navigation
        }
    }

    func editText(changeType: AccountSettingsChangeWithString,
                  hint: String? = nil,
                  displaysNavigationButtons: Bool = false,
                  service: AccountSettingsService) -> ImmuTableRowControllerGenerator
    {
        return { row in
            let editableRow = row as! EditableTextRow
            return self.controllerForEditableText(editableRow,
                                                  changeType: changeType,
                                                  hint: hint,
                                                  displaysNavigationButtons: displaysNavigationButtons,
                                                  service: service)
        }
    }

    func editEmailAddress(changeType: AccountSettingsChangeWithString,
                          hint: String? = nil,
                          displaysNavigationButtons: Bool = false,
                          service: AccountSettingsService) -> ImmuTableRowControllerGenerator
    {
        return { row in
            let editableRow = row as! EditableTextRow
            let settingsViewController =  self.controllerForEditableText(editableRow,
                                                                         changeType: changeType,
                                                                         hint: hint,
                                                                         displaysNavigationButtons: displaysNavigationButtons,
                                                                         service: service)
            settingsViewController.mode = .Email
            
            return settingsViewController
        }
    }
    
    func controllerForEditableText(row: EditableTextRow,
                                   changeType: AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   displaysNavigationButtons: Bool = false,
                                   service: AccountSettingsService) -> SettingsTextViewController
    {
        let title = row.title
        let value = row.value

        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.displaysNavigationButtons = displaysNavigationButtons
        controller.onValueChanged = {
            value in

            let change = changeType(value)
            service.saveChange(change)
            DDLogSwift.logDebug("\(title) changed: \(value)")
        }

        return controller
    }
}