import RxSwift

protocol SettingsController: ImmuTableController {}

// MARK: - Actions
extension SettingsController {
    func editText(changeType: AccountSettingsChangeWithString,
                  hint: String? = nil,
                  isPresented: Bool = false,
                  service: AccountSettingsService) -> ImmuTableRowControllerGenerator
    {
        return { row in
            let editionViewController = self.controllerForEditableText(row as! EditableTextRow,
                                                                       changeType: changeType,
                                                                       hint: hint,
                                                                       isEmail: false,
                                                                       service: service)
            
            if isPresented {
                return UINavigationController(rootViewController: editionViewController)
            }
            
            return editionViewController
        }
    }

    func editEmailAddress(changeType: AccountSettingsChangeWithString,
                          hint: String? = nil,
                          isPresented: Bool = false,
                          service: AccountSettingsService) -> ImmuTableRowControllerGenerator
    {
        return { row in
            let editionViewController = self.controllerForEditableText(row as! EditableTextRow,
                                                                       changeType: changeType,
                                                                       hint: hint,
                                                                       isEmail: true,
                                                                       service: service)
            
            if isPresented {
                return UINavigationController(rootViewController: editionViewController)
            }
            
            return editionViewController
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