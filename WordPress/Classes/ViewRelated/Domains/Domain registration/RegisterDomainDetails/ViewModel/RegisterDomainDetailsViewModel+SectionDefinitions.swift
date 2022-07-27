import Foundation

// MARK: - Section definition

extension RegisterDomainDetailsViewModel {
    typealias EditableKeyValueRow = Row.EditableKeyValueRow
    typealias CheckMarkRow = Row.CheckMarkRow

    class Section {

        enum Change: Equatable {
            case rowValidation(context: ValidationRule.Context, indexPath: IndexPath, isValid: Bool, errorMessage: String?)
            case multipleChoiceRowValueChanged(indexPath: IndexPath, row: EditableKeyValueRow)
            case sectionValidation(context: ValidationRule.Context, sectionIndex: SectionIndex, isValid: Bool)
            case checkMarkRowsUpdated(sectionIndex: SectionIndex)
        }

        private(set) var shouldEnableSubmit: Bool = false {
            didSet {
                if shouldEnableSubmit != oldValue {
                    onChange?(.sectionValidation(context: .clientSide, sectionIndex: sectionIndex, isValid: shouldEnableSubmit))
                }
            }
        }

        private(set) var rows: [RowType]

        let sectionIndex: SectionIndex
        var onChange: ((Change) -> Void)?

        lazy var editableRowValidationStateChangeHandler: EditableKeyValueRow.ValidationStateChangedHandler = { [weak self] (editableRow, rule) in
            guard let strongSelf = self,
                let rowIndex = strongSelf.rowIndex(of: editableRow) else {
                    return
            }
            strongSelf.onChange?(.rowValidation(context: rule.context,
                                                indexPath: IndexPath(row: rowIndex,
                                                                     section: strongSelf.sectionIndex.rawValue),
                                                isValid: editableRow.isValid(inContext: rule.context),
                                                errorMessage: nil))
            switch rule.context {
            case .clientSide:
                strongSelf.shouldEnableSubmit = strongSelf.isValid(inContext: rule.context)
            case .serverSide:
                strongSelf.onChange?(.sectionValidation(context: .serverSide,
                                                        sectionIndex: strongSelf.sectionIndex,
                                                        isValid: strongSelf.isValid(inContext: rule.context)))
            }
        }

        lazy var valueChangeHandler: EditableKeyValueRow.ValueChangeHandler = { [weak self] (editableRow) in
            guard let strongSelf = self,
                let rowIndex = strongSelf.rowIndex(of: editableRow) else {
                    return
            }
            switch editableRow.editingStyle {
            case .multipleChoice:
                let indexPath = IndexPath(row: rowIndex, section: strongSelf.sectionIndex.rawValue)
                strongSelf.onChange?(.multipleChoiceRowValueChanged(indexPath: indexPath, row: editableRow))
            default:
                break
            }
        }

        func rowIndex(of editableRow: Row.EditableKeyValueRow) -> Int? {
            for (index, row) in rows.enumerated() {
                switch row {
                case .inlineEditable(let inlineEditableRow):
                    if inlineEditableRow == editableRow {
                        return index
                    }
                    break
                default:
                    break
                }
            }
            return nil
        }

        init(rows: [RowType], sectionIndex: SectionIndex, onChange: ((Change) -> Void)?) {
            self.rows = rows
            self.sectionIndex = sectionIndex
            self.onChange = onChange
            registerChangeHandlers()
            triggerValidation()
        }

        func insert(_ row: RowType, at index: Int) {
            rows.insert(row, at: index)
            registerChangeHandlers()
        }

        func remove(at index: Int) {
            rows.remove(at: index)
        }

        private func registerChangeHandlers() {
            self.rows.forEach { (row) in
                switch row {
                case .inlineEditable(let editableRow):
                    editableRow.validationStateChangedHandler = self.editableRowValidationStateChangeHandler
                    editableRow.valueChangeHandler = self.valueChangeHandler
                default:
                    break
                }
            }
        }

        func updateValue<T>(_ value: T?, at index: Int) {
            let row = rows[index]
            switch row {
            case .checkMark:
                if let boolValue = value as? Bool, boolValue {
                    selectCheckMarkRow(at: index)
                }
            case .inlineEditable(let inlineEditableRow):
                if let value = value as? String {
                    inlineEditableRow.value = value
                }
            default:
                break
            }
        }

        func isValid(inContext context: ValidationRule.Context) -> Bool {
            for row in rows {
                switch row {
                case .inlineEditable(let editableRow):
                    if !editableRow.isValid(inContext: context) {
                        return false
                    }
                default:
                    break
                }
            }
            return true
        }

        func triggerValidation() {
            rows.forEach { row in
                row.editableRow?.validate()
            }
        }


        func validationErrors(forContext context: ValidationRule.Context) -> [String] {
            var result: [String] = []
            for row in rows {
                switch row {
                case .inlineEditable(let editableRow):
                    result.append(contentsOf: editableRow.validationErrors(forContext: context))
                default:
                    break
                }
            }
            return result
        }

        private func selectCheckMarkRow(at index: Int) {
            var updated = false
            for (iteratedIndex, row) in rows.enumerated() {
                switch row {
                case .checkMark(var iteratedCheckMarkRow):
                    if !iteratedCheckMarkRow.isSelected { //update only if it is unselected before
                        updated = true
                    }
                    iteratedCheckMarkRow.isSelected = iteratedIndex == index
                    rows[iteratedIndex] = .checkMark(iteratedCheckMarkRow)
                default:
                    break
                }
            }
            if updated {
                onChange?(.checkMarkRowsUpdated(sectionIndex: sectionIndex))
            }
        }
    }
}
