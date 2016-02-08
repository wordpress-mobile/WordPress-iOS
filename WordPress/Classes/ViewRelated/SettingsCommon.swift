import RxSwift

protocol SettingsController: ImmuTableController {
    var service: AccountSettingsService { get }
    func mapViewModel(settings: AccountSettings?, presenter: ImmuTablePresenter) -> ImmuTable
}

// MARK: - Shared implementation
extension SettingsController {
    var immutableRows: [ImmuTableRow.Type] {
        return [
            TextRow.self,
            EditableTextRow.self,
            MediaSizeRow.self,
            SwitchRow.self]
    }

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
}

// MARK: - Actions
extension SettingsController {
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