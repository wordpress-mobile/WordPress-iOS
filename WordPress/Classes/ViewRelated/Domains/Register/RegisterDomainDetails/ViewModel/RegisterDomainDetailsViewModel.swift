import Foundation


class RegisterDomainDetailsViewModel {

    typealias Localized = RegisterDomainDetails.Localized
    typealias CodeNameTuple = (code: String, name: String)

    enum Constant {
        static let phoneNumberCountryCodePrefix = "+"
        static let phoneNumberConnectingChar = "."
    }
    enum ValidationRuleTag: String {

        //Tag for rules to decide if we should enable submit button
        case enableSubmit

        //Tag for rules to decide if we should proceed submitting after tapping submit button
        case proceedSubmit
    }

    enum Change: Equatable {
        case rowValidation(tag: ValidationRuleTag, indexPath: IndexPath, isValid: Bool, errorMessage: String?)
        case wholeValidation(tag: ValidationRuleTag, isValid: Bool)
        case sectionValidation(tag: ValidationRuleTag, sectionIndex: Int, isValid: Bool)
        case multipleChoiceRowValueChanged(indexPath: IndexPath)
        case unexpectedError(message: String)
        case addNewAddressLineEnabled(indexPath: IndexPath)
        case addNewAddressLineReplaced(indexPath: IndexPath)
        case checkMarkRowsUpdated(sectionIndex: Int)
        case registerSucceeded(items: [String:String])
        case loading(Bool)
        case prefillSuccess
        case prefillError(message: String)
    }

    enum SectionIndex: Int {
        case privacyProtection
        case contactInformation
        case phone
        case address
    }

    enum Const {
        static let maxExtraAddressLine = 5
    }

    var onChange: ((Change) -> Void)?
    var registerDomainDetailsService: RegisterDomainDetailsServiceProxyProtocol = RegisterDomainDetailsServiceProxy()
    private(set) var addressSectionIndexHelper = CellIndex.AddressSectionIndexHelper()
    private(set) var domain: String
    private(set) var states: [CodeNameTuple]?
    private(set) var countries: [CodeNameTuple]?
    var countryNames: [String] {
        return countries?.map { $0.name } ?? []
    }
    var stateNames: [String] {
        return states?.map { $0.name } ?? []
    }

    private(set) var isLoading: Bool = false {
        didSet {
            onChange?(.loading(isLoading))
        }
    }
    private var dispatchGroup = DispatchGroup()

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
            strongSelf.onChange?(.sectionValidation(tag: tag, sectionIndex: sectionIndex.rawValue, isValid: isSectionValid))
            strongSelf.onChange?(.wholeValidation(tag: tag, isValid: strongSelf.isValid(forTag: tag)))
        case let .checkMarkRowsUpdated(sectionIndex):
            strongSelf.onChange?(.checkMarkRowsUpdated(sectionIndex: sectionIndex.rawValue))
        case let .rowValueChanged(indexPath, row):
            if row.editingStyle == .multipleChoice {
                strongSelf.onChange?(.multipleChoiceRowValueChanged(indexPath: indexPath))
            }
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
            rows: RegisterDomainDetailsViewModel.phoneNumberRows,
            sectionIndex: .phone,
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

    func selectCountry(at index: Int) {
        let section = sections[SectionIndex.contactInformation.rawValue]
        if let row = section.rows[CellIndex.ContactInformation.country.rawValue].editableRow,
            let country = countries?[safe: index] {
            row.idValue = country.code
            row.value = country.name
            fetchStates(countryCode: country.code)
        }
    }

    func selectState(at index: Int) {
        if let state = states?[safe: index] {
            stateRow?.idValue = state.code
            stateRow?.value = state.name
        }
    }

    private func clearStateSelection() {
        stateRow?.idValue = nil
        stateRow?.value = nil
    }

    private var stateRow: EditableKeyValueRow? {
        let section = sections[SectionIndex.address.rawValue]
        return section.rows[safe: addressSectionIndexHelper.stateIndex]?.editableRow
    }

    func prefill() {
        isLoading = true

        dispatchGroup.enter()
        registerDomainDetailsService.getDomainContactInformation(
            success: { [weak self] (domainContactInformation) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.dispatchGroup.leave()
                strongSelf.update(with: domainContactInformation)
                strongSelf.onChange?(.prefillSuccess)
        }) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dispatchGroup.leave()
            strongSelf.onChange?(.prefillError(message: Localized.prefillError))
        }

        dispatchGroup.enter()
        registerDomainDetailsService.getSupportedCountries(success: { [weak self] (countriesResponse) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dispatchGroup.leave()
            var result: [CodeNameTuple] = []
            //Filter empty records
            for country in countriesResponse {
                if let code = country.code,
                    let name = country.name,
                    !code.isEmpty,
                    !name.isEmpty {
                    result.append((code: code, name: name))
                }
            }
            strongSelf.countries = result
        }) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dispatchGroup.leave()
            strongSelf.onChange?(.prefillError(message: Localized.prefillError))
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    private func fetchStates(countryCode: String) {
        isLoading = true
        states = nil
        clearStateSelection()
        registerDomainDetailsService.getStates(
            for: countryCode,
            success: { [weak self] (statesResponse) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.isLoading = false
                var result: [CodeNameTuple] = []
                //Filter empty records
                for state in statesResponse {
                    if let code = state.code,
                        let name = state.name,
                        !code.isEmpty,
                        !name.isEmpty {
                        result.append((code: code, name: name))
                    }
                }
                strongSelf.states = result
        }) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isLoading = false
            strongSelf.onChange?(.unexpectedError(message: Localized.statesFetchingError))
        }
    }

    private func update(with domainContactInformation: DomainContactInformation) {
        //TODO
    }

    private func jsonRepresentation() -> [String: String] {
        var dict: [String: String] = [:]
        if let privacySectionSelectedItem = privacySectionSelectedItem() {
            dict[privacySectionSelectedItem.jsonKey] = String(privacySectionSelectedItem.rawValue)
        }
        dict.merge(phoneNumberSectionJson(), uniquingKeysWith: { (first, _) in first })
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
                dict[editableRow.jsonKey] = editableRow.jsonValue
            default:
                break
            }
        }
        return dict
    }

    private func phoneNumberSectionJson() -> [String: String] {
        let section = sections[SectionIndex.phone.rawValue]
        let jsonKey = section.rows[CellIndex.PhoneNumber.number.rawValue].editableRow?.jsonKey ?? ""
        var dict: [String: String] = [:]
        dict[jsonKey] = formattedPhoneNumber()
        return dict
    }

    private func formattedPhoneNumber() -> String {
        let section = sections[SectionIndex.phone.rawValue]
        let countryCode = section.rows[CellIndex.PhoneNumber.countryCode.rawValue].editableRow?.value ?? ""
        let number = section.rows[CellIndex.PhoneNumber.number.rawValue].editableRow?.value ?? ""
        return Constant.phoneNumberCountryCodePrefix + countryCode +
            Constant.phoneNumberConnectingChar + number
    }
}

// MARK: - Validate remotely

extension RegisterDomainDetailsViewModel {

    fileprivate func validateRemotely(successCompletion: @escaping () -> Void) {
        isLoading = true
        registerDomainDetailsService.validateDomainContactInformation(
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
        updatePhoneNumberValidationErrors(messages: messages)
        updateAddressSectionValidationErrors(messages: messages)
    }

    fileprivate func updatePhoneNumberValidationErrors(messages: ValidateDomainContactInformationResponse.Messages) {
        let rows = sections[SectionIndex.phone.rawValue].rows
        let isValid = messages.isValidPhoneNumber()
        for row in rows {
            row.editableRow?.firstRule(
                forTag: ValidationRuleTag.proceedSubmit.rawValue
                )?.isValid = isValid
        }
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
    typealias PhoneNumber = RegisterDomainDetailsViewModel.CellIndex.PhoneNumber

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
        default:
            return true
        }
    }

    func isValidPhoneNumber() -> Bool {
        return phone?.isEmpty ?? true
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
            return state?.isEmpty ?? true
        default:
            return true
        }
    }
}
