import Foundation

extension RegisterDomainDetailsViewModel {

    typealias RowValidationBlock = ((String?) -> Bool)

    enum ValidationBlock {

        static var nonEmpty: RowValidationBlock = { (text) in
            if let text = text {
                return !text.isEmpty
            }
            return false
        }
        static var email: RowValidationBlock = { (text) in
            return text?.isValidEmail() ?? false
        }
        static var phone: RowValidationBlock = { (text) in
            //TODO: fix
            return text?.isNumeric ?? false
        }
        static var postalCode: RowValidationBlock = { (text) in
            //TODO: fix
            return text?.isNumeric ?? false
        }
    }

    class ValidationRule {

        typealias ValidationStateChangedHandler = ((ValidationRule) -> Void)

        var isValid: Bool = false {
            didSet {
                if isValid != oldValue {
                    validationStateChanged?(self)
                }
            }
        }
        var validationBlock: RowValidationBlock?
        var errorMessage: String?
        var tag: String?
        var validationStateChanged: ValidationStateChangedHandler?

        init(tag: String? = nil,
             validationBlock: RowValidationBlock?,
             errorMessage: String?) {
            self.tag = tag
            self.validationBlock = validationBlock
            self.errorMessage = errorMessage
        }

        func validate(text: String?) {
            isValid = validationBlock?(text) ?? true
        }
    }

    enum Row {

        struct CheckMarkRow: Equatable {
            var isSelected: Bool
            var title: String
        }

        class EditableKeyValueRow: Equatable {

            typealias ValidationStateChangedHandler = ((EditableKeyValueRow, ValidationRule) -> Void)

            enum EditingStyle: Int {
                case inline
                case multipleChoice
            }

            var key: String
            var jsonKey: String
            var value: String? {
                didSet {
                   validate()
                }
            }
            var placeholder: String?
            var validationRules: [ValidationRule]?
            var editingStyle: EditingStyle = .inline
            var validationStateChangedHandler: ValidationStateChangedHandler? {
                didSet {
                    registerForValidationStateChangedEvent()
                }
            }

            init(key: String,
                 jsonKey: String,
                 value: String?,
                 placeholder: String?,
                 editingStyle: EditingStyle,
                 validationRules: [ValidationRule]? = nil) {

                self.key = key
                self.jsonKey = jsonKey
                self.value = value
                self.placeholder = placeholder
                self.editingStyle = editingStyle
                self.validationRules = validationRules
            }

            private func registerForValidationStateChangedEvent() {
                if let rules = validationRules {
                    for rule in rules {
                        rule.validationStateChanged = { [weak self] (rule) in
                            guard let strongSelf = self else { return }
                            strongSelf.validationStateChangedHandler?(strongSelf, rule)
                        }
                    }
                }
            }

            func validate() {
                if let rules = validationRules {
                    for rule in rules {
                        rule.validate(text: value)
                    }
                }
            }

            func validate(forTag tag: String) {
                if let rules = validationRules {
                    for (index, rule) in rules.enumerated() {
                        if rule.tag == tag {
                            validationRules?[index].validate(text: value)
                        }
                    }
                }
            }

            func validationErrors(forTag tag: String) -> [String] {
                var result: [String] = []
                if let validationRules = validationRules {
                    validationRules
                        .filter {
                            return $0.tag == tag && !$0.isValid
                        }
                        .forEach {
                            if let message = $0.errorMessage {
                                result.append(message)
                            }
                        }
                }
                return result
            }

            func isValid(forTag tag: String) -> Bool {
                if let validationRules = validationRules {
                    return validationRules.filter {
                        return $0.tag == tag && !$0.isValid
                        }.count == 0
                }
                return true
            }

            static func == (lhs: EditableKeyValueRow, rhs: EditableKeyValueRow) -> Bool {
                return lhs.editingStyle == rhs.editingStyle
                    && lhs.key == rhs.key
                    && lhs.value == rhs.value
                    && lhs.placeholder == rhs.placeholder
            }
        }
    }
}

extension RegisterDomainDetailsViewModel.Row.EditableKeyValueRow {

    func accessoryType() -> UITableViewCellAccessoryType {
        switch editingStyle {
        case .inline:
            return .none
        case .multipleChoice:
            return .disclosureIndicator
        }
    }
}
