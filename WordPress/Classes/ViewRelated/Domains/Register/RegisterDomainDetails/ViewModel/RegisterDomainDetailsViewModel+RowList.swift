import Foundation

// MARK: - Row list

extension RegisterDomainDetailsViewModel {

    enum RowType: Equatable {
        case checkMark(Row.CheckMarkRow)
        case inlineEditable(Row.EditableKeyValueRow)
        case addAddressLine(title: String?)

        var editableRow: Row.EditableKeyValueRow? {
            switch self {
            case .inlineEditable(let row):
                return row
            default:
                return nil
            }
        }
    }

    static var privacyProtectionRows: [RowType] {
        return [
            .checkMark(.init(
                isSelected: true,
                title: Localized.PrivacySection.registerPrivatelyRowText
                )),
            .checkMark(.init(
                isSelected: false,
                title: Localized.PrivacySection.registerPubliclyRowText
                ))
        ]
    }

    static var nonEmptyRule: ValidationRule {
        return ValidationRule(tag: ValidationRuleTag.enableSubmit.rawValue,
                              validationBlock: ValidationBlock.nonEmpty,
                              errorMessage: nil)
    }

    static func proceedRule(with key: String, hasErrorMessage: Bool = true) -> ValidationRule {
        return ValidationRule(tag: ValidationRuleTag.proceedSubmit.rawValue,
                              validationBlock: nil, //validation is handled on serverside
            errorMessage: hasErrorMessage ? String(format: Localized.validationError, key) : nil)
    }

    static var contactInformationRows: [RowType] {
        return [
            .inlineEditable(.init(
                key: Localized.ContactInformation.firstName,
                jsonKey: "first_name",
                value: nil,
                placeholder: Localized.ContactInformation.firstName,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  proceedRule(with: Localized.ContactInformation.firstName)]
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.lastName,
                jsonKey: "last_name",
                value: nil,
                placeholder: Localized.ContactInformation.lastName,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  proceedRule(with: Localized.ContactInformation.lastName)]
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.organization,
                jsonKey: "organization",
                value: nil,
                placeholder: Localized.ContactInformation.organizationPlaceholder,
                editingStyle: .inline
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.email,
                jsonKey: "email",
                value: nil,
                placeholder: Localized.ContactInformation.email,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  proceedRule(with: Localized.ContactInformation.email)]
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.country,
                jsonKey: "country_code",
                value: nil,
                placeholder: Localized.ContactInformation.countryPlaceholder,
                editingStyle: .multipleChoice,
                validationRules: [nonEmptyRule,
                                  proceedRule(with: Localized.ContactInformation.country)]
                ))]
    }

    static var phoneNumberRows: [RowType] {
        return [
            .inlineEditable(.init(
                key: Localized.PhoneNumber.countryCode,
                jsonKey: "phone",
                value: nil,
                placeholder: Localized.PhoneNumber.countryCodePlaceholder,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  proceedRule(with: Localized.ContactInformation.phone, hasErrorMessage: false)]
                )),
            .inlineEditable(.init(
                key: Localized.PhoneNumber.number,
                jsonKey: "phone",
                value: nil,
                placeholder: Localized.PhoneNumber.numberPlaceholder,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  proceedRule(with: Localized.ContactInformation.phone)]
                ))
        ]
    }

    static func addressLine(row: Int, optional: Bool = true) -> RowType {
        let key = String(format: Localized.Address.addressLine, "\(row + 1)")
        return .inlineEditable(.init(
            key: key,
            jsonKey: String(format: "address_%@", "\(row + 1)"),
            value: nil,
            placeholder: Localized.Address.addressPlaceholder,
            editingStyle: .inline,
            validationRules: optional ? nil : [nonEmptyRule, proceedRule(with: key)]
            ))
    }

    static var addressRows: [RowType] {
        return [
            addressLine(row: 0, optional: false),
            .inlineEditable(.init(
                key: Localized.Address.city,
                jsonKey: "city",
                value: nil,
                placeholder: Localized.Address.city,
                editingStyle: .inline,
                validationRules: [nonEmptyRule, proceedRule(with: Localized.Address.city)]
                )),
            .inlineEditable(.init(
                key: Localized.Address.state,
                jsonKey: "state",
                value: nil,
                placeholder: Localized.Address.statePlaceHolder,
                editingStyle: .multipleChoice,
                validationRules: [proceedRule(with: Localized.Address.state)]
                )),
            .inlineEditable(.init(
                key: Localized.Address.postalCode,
                jsonKey: "postal_code",
                value: nil,
                placeholder: Localized.Address.postalCode,
                editingStyle: .inline,
                validationRules: [nonEmptyRule, proceedRule(with: Localized.Address.postalCode)]
                ))
        ]
    }
}
