import Foundation


class RegisterDomainDetailsViewModel {

    typealias Localized = RegisterDomainDetails.Localized

    enum ValidationRuleTag: String {

        //Tag for rules to decide if we should enable submit button
        case enableSubmit

        //Tag for rules to decide if we should proceed submitting after tapping submit button
        case proceedSubmit
    }

    enum Change: Equatable {
        case rowValidation(tag: ValidationRuleTag, indexPath: IndexPath, isValid: Bool, errorMessage: String?)
        case wholeValidation(tag: ValidationRuleTag, isValid: Bool)
        case registerFailedBecauseOfValidation
        case unexpectedError(message: String)
        case addNewAddressLineEnabled(indexPath: IndexPath)
        case addNewAddressLineReplaced(indexPath: IndexPath)
        case checkMarkRowsUpdated(sectionIndex: Int)
        case registerSucceeded(items: [String:String])
        case loading(Bool)
    }

    enum SectionIndex: Int {
        case privacyProtection
        case contactInformation
        case address
    }

    enum Const {
        static let maxExtraAddressLine = 5
    }

    var onChange: ((Change) -> Void)?
    private(set) var addressSectionIndexHelper = CellIndex.AddressSectionIndexHelper()
    private(set) var domain: String
    private(set) var isLoading: Bool = false {
        didSet {
            onChange?(.loading(isLoading))
        }
    }

    init(domain: String) {
        self.domain = domain
    }

    lazy var sectionChangeHandler: ((Section.Change) -> Void)? = { [weak self] (change) in
        guard let strongSelf = self else { return }

        switch change {
        case let .rowValidation(tag, indexPath, isValid, errorMessage):
            strongSelf.onChange?(.rowValidation(tag: tag,
                                                indexPath: indexPath,
                                                isValid: isValid,
                                                errorMessage: errorMessage))
        case let .sectionValidation(tag, sectionIndex, isSectionValid):
            let valid = strongSelf.isValid(forTag: tag)
            strongSelf.onChange?(.wholeValidation(tag: tag, isValid: valid))
        case let .checkMarkRowsUpdated(sectionIndex):
            strongSelf.onChange?(.checkMarkRowsUpdated(sectionIndex: sectionIndex.rawValue))
        }
    }

    lazy var sections = [
        Section(
            rows: RegisterDomainDetailsViewModel.privacyProtectionRows,
            sectionIndex: .privacyProtection,
            onChange: sectionChangeHandler
        ),
        Section(
            rows: RegisterDomainDetailsViewModel.contactInformationRows,
            sectionIndex: .contactInformation,
            onChange: sectionChangeHandler
        ),
        Section(
            rows: RegisterDomainDetailsViewModel.addressRows,
            sectionIndex: .address,
            onChange: sectionChangeHandler
        )
    ]

    func enableAddAddressRow() {
        if !addressSectionIndexHelper.isAddNewAddressVisible
            && Const.maxExtraAddressLine > addressSectionIndexHelper.addNewAddressIndex {
            addressSectionIndexHelper.isAddNewAddressVisible = true
            sections[SectionIndex.address.rawValue].insert(
                .addAddressLine(
                    title: String(
                        format: Localized.Address.addNewAddressLine,
                        "\(addressSectionIndexHelper.addNewAddressIndex + 1)"
                    )
                ),
                at: addressSectionIndexHelper.addNewAddressIndex
            )
            onChange?(
                .addNewAddressLineEnabled(
                    indexPath: IndexPath(
                        row: addressSectionIndexHelper.addNewAddressIndex,
                        section: SectionIndex.address.rawValue
                    )
                ))
        }
    }

    func replaceAddNewAddressLine() {
        if addressSectionIndexHelper.isAddNewAddressVisible {
            addressSectionIndexHelper.addNewAddressField()
            addressSectionIndexHelper.isAddNewAddressVisible = false
            sections[SectionIndex.address.rawValue].remove(at: addressSectionIndexHelper.addNewAddressIndex)
            sections[SectionIndex.address.rawValue].insert(
                RegisterDomainDetailsViewModel.addressLine(
                    row: addressSectionIndexHelper.addNewAddressIndex
                ),
                at: addressSectionIndexHelper.addNewAddressIndex
            )
            onChange?(.addNewAddressLineReplaced(indexPath: IndexPath(
                row: addressSectionIndexHelper.addNewAddressIndex,
                section: SectionIndex.address.rawValue
            )))
        }
    }

    func updateValue<T>(_ value: T?, at indexPath: IndexPath) {
        sections[indexPath.section].updateValue(value, at: indexPath.row)
    }

    func isValid(forTag tag: ValidationRuleTag) -> Bool {
        for section in sections {
            if !section.isValid(forTag: tag) {
                return false
            }
        }
        return true
    }

    func register() {
        validateRemotely(successCompletion: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            //TODO: Call the registeration service here
            strongSelf.onChange?(.registerSucceeded(items: strongSelf.jsonRepresentation()))
        })
    }

    private func jsonRepresentation() -> [String: String] {
        var dict: [String: String] = [:]
        if let privacySectionSelectedItem = privacySectionSelectedItem() {
            dict[privacySectionSelectedItem.jsonKey] = String(privacySectionSelectedItem.rawValue)
        }
        dict.merge(sectionJson(sectionIndex: .contactInformation), uniquingKeysWith: { (first, _) in first })
        dict.merge(sectionJson(sectionIndex: .address), uniquingKeysWith: { (first, _) in first })
        return dict
    }

    private func privacySectionSelectedItem() -> CellIndex.PrivacyProtection? {
        let privacySection = sections[SectionIndex.privacyProtection.rawValue]
        for (index, row) in privacySection.rows.enumerated() {
            switch row {
            case .checkMark(let checkMarkRow):
                if checkMarkRow.isSelected {
                    return CellIndex.PrivacyProtection(rawValue: index)
                }
            default:
                break
            }
        }
        return nil
    }

    private func sectionJson(sectionIndex: SectionIndex) -> [String: String] {
        var dict: [String: String] = [:]
        let section = sections[sectionIndex.rawValue]
        for row in section.rows {
            switch row {
            case .inlineEditable(let editableRow):
                dict[editableRow.jsonKey] = editableRow.value
            default:
                break
            }
        }
        return dict
    }
}

// MARK: - Validate remotely

extension RegisterDomainDetailsViewModel {

    fileprivate func validateRemotely(successCompletion: @escaping () -> Void) {
        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let api = accountService.defaultWordPressComAccount()?.wordPressComRestApi ?? WordPressComRestApi(oAuthToken: "")
        let remoteService = DomainsServiceRemote(wordPressComRestApi: api)
        isLoading = true
        remoteService.validateDomainContactInformation(
            contactInformation: jsonRepresentation(),
            domainNames: [domain],
            success: { [weak self] (response) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.isLoading = false
                if response.success {
                    strongSelf.clearValidationErrors()
                    successCompletion()
                } else {
                    strongSelf.updateValidationErrors(with: response.messages)
                    strongSelf.onChange?(.registerFailedBecauseOfValidation)
                }
        }) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isLoading = false
            strongSelf.onChange?(.unexpectedError(message: Localized.unexpectedError))
        }
    }

    fileprivate func clearValidationErrors() {
        for section in sections {
            for row in section.rows {
                if let editableRow = row.editableRow {
                    editableRow.firstRule(
                        forTag: ValidationRuleTag.proceedSubmit.rawValue
                        )?.isValid = true
                }
            }
        }
    }

    fileprivate func updateValidationErrors(with messages: ValidateDomainContactInformationResponse.Messages?) {
        guard let messages = messages else {
            return
        }
        updateContactInformationValidationErrors(messages: messages)
        updateAddressSectionValidationErrors(messages: messages)
    }

    fileprivate func updateContactInformationValidationErrors(messages: ValidateDomainContactInformationResponse.Messages) {
        let rows = sections[SectionIndex.contactInformation.rawValue].rows
        for (index, row) in rows.enumerated() {
            if let editableRow = row.editableRow,
                let cellIndex = CellIndex.ContactInformation(rawValue: index) {
                editableRow.firstRule(
                    forTag: ValidationRuleTag.proceedSubmit.rawValue
                    )?.isValid = messages.isValid(for: cellIndex)
            }
        }
    }

    fileprivate func updateAddressSectionValidationErrors(messages: ValidateDomainContactInformationResponse.Messages) {
        let rows = sections[SectionIndex.address.rawValue].rows
        for (index, row) in rows.enumerated() {
            if let editableRow = row.editableRow {
                let addressField = addressSectionIndexHelper.addressField(for: index)
                editableRow.firstRule(
                    forTag: ValidationRuleTag.proceedSubmit.rawValue
                    )?.isValid = messages.isValid(addressField: addressField)
            }
        }
    }
}

extension ValidateDomainContactInformationResponse.Messages {

    typealias ContactInformation = RegisterDomainDetailsViewModel.CellIndex.ContactInformation
    typealias AddressField = RegisterDomainDetailsViewModel.CellIndex.AddressField

    func isValid(for index: ContactInformation) -> Bool {
        switch index {
        case .country:
            return countryCode?.isEmpty ?? true
        case .email:
            return email?.isEmpty ?? true
        case .firstName:
            return firstName?.isEmpty ?? true
        case .lastName:
            return lastName?.isEmpty ?? true
        case .phone:
            return phone?.isEmpty ?? true
        default:
            return true
        }
    }

    func isValid(addressField: AddressField) -> Bool {
        switch addressField {
        case .addressLine:
            return address1?.isEmpty ?? true
        case .city:
            return city?.isEmpty ?? true
        case .postalCode:
            return postalCode?.isEmpty ?? true
        case .state:
            return postalCode?.isEmpty ?? true
        default:
            return true
        }
    }
}
