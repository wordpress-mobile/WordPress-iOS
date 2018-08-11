import Foundation

// MARK: - Section definition

extension RegisterDomainDetailsViewModel {
    typealias EditableKeyValueRow = Row.EditableKeyValueRow
    typealias CheckMarkRow = Row.CheckMarkRow

    class Section {

        enum Change: Equatable {
            case rowValidation(tag: ValidationRuleTag, indexPath: IndexPath, isValid: Bool, errorMessage: String?)
            case rowValueChanged(indexPath: IndexPath, row: EditableKeyValueRow)
            case sectionValidation(tag: ValidationRuleTag, sectionIndex: SectionIndex, isValid: Bool)
            case checkMarkRowsUpdated(sectionIndex: SectionIndex)
        }

        private(set) var shouldEnableSubmit: Bool = false {
            didSet {
                if shouldEnableSubmit != oldValue {
                    onChange?(.sectionValidation(tag: .enableSubmit, sectionIndex: sectionIndex, isValid: shouldEnableSubmit))
                }
            }
        }

        private(set) var rows: [RowType]

        let sectionIndex: SectionIndex
        var onChange: ((Change) -> Void)?

        lazy var editableRowValidationStateChangeHandler: EditableKeyValueRow.ValidationStateChangedHandler = { [weak self] (editableRow, rule) in
            guard let strongSelf = self,
                let rowIndex = strongSelf.rowIndex(of: editableRow),
                let tag = rule.tag,
                let ruleTag = ValidationRuleTag(rawValue: tag) else {
                    return
            }
            strongSelf.onChange?(.rowValidation(tag: ruleTag,
                                                indexPath: IndexPath(row: rowIndex,
                                                                     section: strongSelf.sectionIndex.rawValue),
                                                isValid: editableRow.isValid(forTag: ruleTag.rawValue),
                                                errorMessage: nil))
            switch ruleTag {
            case .enableSubmit:
                strongSelf.shouldEnableSubmit = strongSelf.isValid(forTag: ruleTag)
            case .proceedSubmit:
                strongSelf.onChange?(.sectionValidation(tag: .proceedSubmit,
                                                        sectionIndex: strongSelf.sectionIndex,
                                                        isValid: strongSelf.isValid(forTag: ruleTag)))
            }
        }

        lazy var valueChangeHandler: EditableKeyValueRow.ValueChangeHandler = { [weak self] (editableRow) in
            guard let strongSelf = self,
                let rowIndex = strongSelf.rowIndex(of: editableRow) else {
                    return
            }
            let indexPath = IndexPath(row: rowIndex, section: strongSelf.sectionIndex.rawValue)
            strongSelf.onChange?(.rowValueChanged(indexPath: indexPath, row: editableRow))
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

        func isValid(forTag tag: ValidationRuleTag) -> Bool {
            for row in rows {
                switch row {
                case .inlineEditable(let editableRow):
                    if !editableRow.isValid(forTag: tag.rawValue) {
                        return false
                    }
                default:
                    break
                }
            }
            return true
        }

        func validationErrors(forTag tag: ValidationRuleTag) -> [String] {
            var result: [String] = []
            for row in rows {
                switch row {
                case .inlineEditable(let editableRow):
                    result.append(contentsOf: editableRow.validationErrors(forTag: tag.rawValue))
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
