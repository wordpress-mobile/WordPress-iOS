import RxSwift

protocol SettingsController: ImmuTableController {
    var service: AccountSettingsService { get }
    var presenter: ImmuTablePresenter? { get }
    func mapViewModel(settings: AccountSettings?) -> ImmuTable
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

    var immuTable: Observable<ImmuTable> {
        precondition(presenter != nil, "presenter must be set before using")
        return service.settings.map(mapViewModel)
    }

    var errorMessage: Observable<String?> {
        precondition(presenter != nil, "presenter must be set before using")
        guard let presenter = presenter else {
            // This shouldn't happen, but if it does, disabling the error feels
            // safer than having it running when the VC is not visible.
            return Observable.just(nil)
        }
        return service.refresh
            .pausable(presenter.visible)
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