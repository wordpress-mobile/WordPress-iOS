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

        static var validEmail: RowValidationBlock = { (text) in
            guard let email = text else {
                return false
            }
            return EmailFormatValidator.validate(string: email)
        }
    }

    class ValidationRule {
        enum Context: String {

            //Tag for rules to decide if we should enable submit button
            case clientSide

            //Tag for rules to decide if we should proceed submitting after tapping submit button
            case serverSide
        }

        typealias ValidationStateChangedHandler = ((ValidationRule) -> Void)

        var isValid: Bool = true {
            didSet {
                validationStateChanged?(self)
            }
        }
        var validationBlock: RowValidationBlock?
        var errorMessage: String?
        var serverSideErrorMessage: String?
        var context: Context
        var validationStateChanged: ValidationStateChangedHandler?

        init(context: Context,
             validationBlock: RowValidationBlock?,
             errorMessage: String?) {
            self.context = context
            self.validationBlock = validationBlock
            self.errorMessage = errorMessage
        }

        func validate(text: String?) {
            isValid = validationBlock?(text) ?? isValid
        }
    }

    enum Row {

        struct CheckMarkRow: Equatable {
            var isSelected: Bool
            var title: String
        }

        class EditableKeyValueRow: Equatable {

            typealias ValidationStateChangedHandler = ((EditableKeyValueRow, ValidationRule) -> Void)
            typealias ValueChangeHandler = ((EditableKeyValueRow) -> Void)
            typealias ValueSanitizerBlock = (_ value: String?) -> String?

            enum EditingStyle: Int {
                case inline
                case multipleChoice
            }

            var key: String
            var jsonKey: String
            var value: String? {
                didSet {
                    validate()
                    valueChangeHandler?(self)
                }
            }
            var idValue: String?
            var jsonValue: String? {
                switch editingStyle {
                case .inline:
                    return value
                case .multipleChoice:
                    return idValue
                }
            }
            var placeholder: String?
            var validationRules: [ValidationRule]
            var editingStyle: EditingStyle = .inline
            var validationStateChangedHandler: ValidationStateChangedHandler? {
                didSet {
                    registerForValidationStateChangedEvent()
                }
            }
            var valueChangeHandler: ValueChangeHandler?
            var valueSanitizer: ValueSanitizerBlock?

            init(key: String,
                 jsonKey: String,
                 value: String?,
                 placeholder: String?,
                 editingStyle: EditingStyle,
                 validationRules: [ValidationRule] = [],
                 valueSanitizer: ValueSanitizerBlock? = nil) {

                self.key = key
                self.jsonKey = jsonKey
                self.value = value
                self.placeholder = placeholder
                self.editingStyle = editingStyle
                self.validationRules = validationRules
                self.valueSanitizer = valueSanitizer
            }

            private func registerForValidationStateChangedEvent() {
                for rule in validationRules {
                    rule.validationStateChanged = { [weak self] (rule) in
                        guard let strongSelf = self else { return }
                        strongSelf.validationStateChangedHandler?(strongSelf, rule)
                    }
                }
            }

            func validate() {
                validationRules.forEach { $0.validate(text: value) }
            }

            func validate(forContext context: ValidationRule.Context) {
                validationRules
                    .filter { $0.context == context }
                    .forEach { $0.validate(text: value) }
            }

            func firstRule(forContext context: ValidationRule.Context) -> ValidationRule? {
                return validationRules.first { $0.context == context }
            }

            func validationErrors(forContext context: ValidationRule.Context) -> [String] {
                return validationRules
                    .filter { return $0.context == context && !$0.isValid && $0.errorMessage != nil }
                    .compactMap { "\($0.errorMessage ?? ""). \($0.serverSideErrorMessage ?? "")" }
            }

            func isValid(inContext context: ValidationRule.Context) -> Bool {
                let hasErrors = validationRules
                    .filter { return $0.context == context }
                    .contains { $0.isValid == false }

                return !hasErrors
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

    func accessoryType() -> UITableViewCell.AccessoryType {
        switch editingStyle {
        case .inline:
            return .none
        case .multipleChoice:
            return .disclosureIndicator
        }
    }
}
