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
        return ValidationRule(context: .clientSide,
                              validationBlock: ValidationBlock.nonEmpty,
                              errorMessage: nil)
    }

    static var emailRule: ValidationRule {
        return ValidationRule(context: .clientSide,
                              validationBlock: ValidationBlock.validEmail,
                              errorMessage: "not email")
    }

    static func serverSideRule(with key: String, hasErrorMessage: Bool = true) -> ValidationRule {
        let errorMessage: String?

        if !hasErrorMessage {
            errorMessage = nil
        } else {
            switch key {
            case Localized.ContactInformation.firstName:
                errorMessage = Localized.validationErrorFirstName
            case Localized.ContactInformation.lastName:
                errorMessage = Localized.validationErrorLastName
            case Localized.ContactInformation.organization:
                errorMessage = Localized.validationErrorOrganization
            case Localized.ContactInformation.email:
                errorMessage = Localized.validationErrorEmail
            case Localized.ContactInformation.country:
                errorMessage = Localized.validationErrorCountry
            case Localized.ContactInformation.phone:
                errorMessage = Localized.validationErrorPhone
            case Localized.Address.addressLine:
                errorMessage = Localized.validationErrorAddress
            case Localized.Address.city:
                errorMessage = Localized.validationErrorCity
            case Localized.Address.state:
                errorMessage = Localized.validationErrorState
            case Localized.Address.postalCode:
                errorMessage = Localized.validationErrorPostalCode
            default:
                errorMessage = nil
            }
        }

        return ValidationRule(context: .serverSide,
                              validationBlock: nil, //validation is handled on serverside
                              errorMessage: errorMessage)
    }

    static func transformToLatinASCII(value: String?) -> String? {
        let toLatinASCII = StringTransform(rawValue: "Latin-ASCII") // See http://userguide.icu-project.org/transforms/general for more options.
        return value?.applyingTransform(toLatinASCII, reverse: false)
    }

    // MARK: - Rows

    static var contactInformationRows: [RowType] {
        return [
            .inlineEditable(.init(
                key: Localized.ContactInformation.firstName,
                jsonKey: "first_name",
                value: nil,
                placeholder: Localized.ContactInformation.firstName,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  serverSideRule(with: Localized.ContactInformation.firstName)],
                valueSanitizer: transformToLatinASCII
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.lastName,
                jsonKey: "last_name",
                value: nil,
                placeholder: Localized.ContactInformation.lastName,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  serverSideRule(with: Localized.ContactInformation.lastName)],
                valueSanitizer: transformToLatinASCII
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.organization,
                jsonKey: "organization",
                value: nil,
                placeholder: Localized.ContactInformation.organizationPlaceholder,
                editingStyle: .inline,
                validationRules: [serverSideRule(with: Localized.ContactInformation.organization)],
                valueSanitizer: transformToLatinASCII
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.email,
                jsonKey: "email",
                value: nil,
                placeholder: Localized.ContactInformation.email,
                editingStyle: .inline,
                validationRules: [emailRule,
                                  nonEmptyRule,
                                  serverSideRule(with: Localized.ContactInformation.email)]
                )),
            .inlineEditable(.init(
                key: Localized.ContactInformation.country,
                jsonKey: "country_code",
                value: nil,
                placeholder: Localized.ContactInformation.countryPlaceholder,
                editingStyle: .multipleChoice,
                validationRules: [nonEmptyRule,
                                  serverSideRule(with: Localized.ContactInformation.country)]
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
                                  serverSideRule(with: Localized.ContactInformation.phone, hasErrorMessage: false)]
                )),
            .inlineEditable(.init(
                key: Localized.PhoneNumber.number,
                jsonKey: "phone",
                value: nil,
                placeholder: Localized.PhoneNumber.numberPlaceholder,
                editingStyle: .inline,
                validationRules: [nonEmptyRule,
                                  serverSideRule(with: Localized.ContactInformation.phone)]
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
            validationRules: optional ? [serverSideRule(with: Localized.Address.addressLine)] : [nonEmptyRule, serverSideRule(with: Localized.Address.addressLine)],
            valueSanitizer: transformToLatinASCII
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
                validationRules: [nonEmptyRule, serverSideRule(with: Localized.Address.city)],
                valueSanitizer: transformToLatinASCII
                )),
            .inlineEditable(.init(
                key: Localized.Address.state,
                jsonKey: "state",
                value: nil,
                placeholder: Localized.Address.statePlaceHolder,
                editingStyle: .multipleChoice,
                validationRules: [serverSideRule(with: Localized.Address.state)],
                valueSanitizer: transformToLatinASCII
                )),
            .inlineEditable(.init(
                key: Localized.Address.postalCode,
                jsonKey: "postal_code",
                value: nil,
                placeholder: Localized.Address.postalCode,
                editingStyle: .inline,
                validationRules: [nonEmptyRule, serverSideRule(with: Localized.Address.postalCode)],
                valueSanitizer: transformToLatinASCII
                ))
        ]
    }
}
