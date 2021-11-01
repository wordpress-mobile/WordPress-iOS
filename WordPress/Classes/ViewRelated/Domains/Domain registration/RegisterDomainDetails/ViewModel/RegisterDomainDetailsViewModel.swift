import Foundation

class RegisterDomainDetailsViewModel {

    typealias Localized = RegisterDomainDetails.Localized
    typealias CodeNameTuple = (code: String, name: String)

    enum Constant {
        static let phoneNumberCountryCodePrefix = "+"
        static let phoneNumberConnectingChar: Character = "."
        static let maxExtraAddressLine = 5
    }

    enum Change: Equatable {
        case rowValidated(context: ValidationRule.Context, indexPath: IndexPath, isValid: Bool, errorMessage: String?)
        case sectionValidated(context: ValidationRule.Context, sectionIndex: Int, isValid: Bool)
        case formValidated(context: ValidationRule.Context, isValid: Bool)

        case multipleChoiceRowValueChanged(indexPath: IndexPath)

        case addNewAddressLineEnabled(indexPath: IndexPath)
        case addNewAddressLineReplaced(indexPath: IndexPath)

        case checkMarkRowsUpdated(sectionIndex: Int)

        case registerSucceeded(_ domain: String)
        case domainIsPrimary(domain: String)

        case loading(Bool)

        case remoteValidationFinished

        case prefillSuccess
        case prefillError(message: String)

        case unexpectedError(message: String)
    }

    enum SectionIndex: Int {
        case privacyProtection
        case contactInformation
        case phone
        case address
    }

    var onChange: ((Change) -> Void)?

    var registerDomainDetailsService: RegisterDomainDetailsServiceProxyProtocol = RegisterDomainDetailsServiceProxy()

    let domain: FullyQuotedDomainSuggestion
    let siteID: Int
    let domainPurchasedCallback: ((String) -> Void)

    private(set) var addressSectionIndexHelper = CellIndex.AddressSectionIndexHelper()
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

    init(siteID: Int, domain: FullyQuotedDomainSuggestion, domainPurchasedCallback: @escaping ((String) -> Void)) {
        self.siteID = siteID
        self.domain = domain
        self.domainPurchasedCallback = domainPurchasedCallback
        manuallyTriggerValidation()
    }

    lazy var sectionChangeHandler: ((Section.Change) -> Void)? = { [weak self] (change) in
        guard let strongSelf = self else { return }

        switch change {
        case let .rowValidation(context, indexPath, isValid, errorMessage):
            strongSelf.onChange?(.rowValidated(context: context,
                                                indexPath: indexPath,
                                                isValid: isValid,
                                                errorMessage: errorMessage))
        case let .sectionValidation(context, sectionIndex, isSectionValid):
            strongSelf.onChange?(.sectionValidated(context: context, sectionIndex: sectionIndex.rawValue, isValid: isSectionValid))
            strongSelf.onChange?(.formValidated(context: context, isValid: strongSelf.isValid(inContext: context)))
        case let .checkMarkRowsUpdated(sectionIndex):
            strongSelf.onChange?(.checkMarkRowsUpdated(sectionIndex: sectionIndex.rawValue))
        case let .multipleChoiceRowValueChanged(indexPath, row):
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
            && Constant.maxExtraAddressLine > addressSectionIndexHelper.addNewAddressIndex {
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

    func isValid(inContext context: ValidationRule.Context) -> Bool {
        for section in sections {
            if !section.isValid(inContext: context) {
                return false
            }
        }
        return true
    }

    private func manuallyTriggerValidation() {
        sections.forEach {
            $0.triggerValidation()
        }
    }

    func register() {
        let domainSuggestion = domain
        let contactInformation = jsonRepresentation()
        let privacyEnabled = privacySectionSelectedItem() == CellIndex.PrivacyProtection.privately
        let registerDomainService = registerDomainDetailsService
        let siteID = siteID
        let onChange = onChange

        isLoading = true
        validateRemotely(successCompletion: { [weak self] in
            WPAnalytics.track(.automatedTransferCustomDomainContactInfoValidated)

            registerDomainService.purchaseDomainUsingCredits(
                siteID: siteID,
                domainSuggestion: domainSuggestion.remoteSuggestion(),
                domainContactInformation: contactInformation,
                privacyProtectionEnabled: privacyEnabled,
                success: { domain in
                    registerDomainService.setPrimaryDomain(
                        siteID: siteID,
                        domain: domain,
                        success: {
                            self?.isLoading = false

                            WPAnalytics.track(.automatedTransferCustomDomainPurchased)

                            onChange?(.registerSucceeded(domain))
                            onChange?(.domainIsPrimary(domain: domain))
                        }, failure: { _ in
                            self?.isLoading = false

                            // Setting the domain as primary doesn't affect the success of registering the domain
                            // so we'll simply ignore this for now.  If we want to highlight this as an error to
                            // the user we could opt to show a Notice in the future.
                            onChange?(.registerSucceeded(domain))
                        })
                }, failure: { error in
                    // Same as above. If adding items to cart fails, not much we can do to recover :(
                    WPAnalytics.track(.automatedTransferCustomDomainPurchaseFailed)
                    self?.isLoading = false
                    onChange?(.prefillError(message: Localized.redemptionError))
                })
        })
    }

    func selectCountry(at index: Int) {
        let section = sections[SectionIndex.contactInformation.rawValue]
        if let row = section.rows[CellIndex.ContactInformation.country.rawValue].editableRow,
            let country = countries?[safe: index] {
            row.idValue = country.code
            row.value = country.name
            fetchStates(countryCode: country.code)

            prefillCountryCodePrefix(countryCode: country.code)
            onChange?(.prefillSuccess)
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
        fetchCountries { [weak self] in
            self?.fetchDomainContactInformation()
        }
    }

    private func fetchDomainContactInformation() {
        isLoading = true
        registerDomainDetailsService.getDomainContactInformation(
            success: { [weak self] (domainContactInformation) in
                guard let strongSelf = self else {
                    return
                }

                defer {
                    strongSelf.isLoading = false
                }

                let prefillSuccessBlock = {
                    strongSelf.update(with: domainContactInformation)
                    strongSelf.onChange?(.prefillSuccess)

                }
                if let countryCode = domainContactInformation.countryCode {
                    strongSelf.prefillCountryCodePrefix(countryCode: countryCode)
                    strongSelf.fetchStates(countryCode: countryCode) {
                        prefillSuccessBlock()
                    }
                } else {
                    prefillSuccessBlock()
                }
        }) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isLoading = false
            strongSelf.onChange?(.prefillError(message: Localized.prefillError))
        }
    }

    private func fetchCountries(successCompletion: @escaping () -> Void) {
        isLoading = true
        registerDomainDetailsService.getSupportedCountries(success: { [weak self] (countriesResponse) in
            guard let strongSelf = self else {
                return
            }

            defer {
                strongSelf.isLoading = false
            }

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
            successCompletion()
        }) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isLoading = false
            strongSelf.onChange?(.prefillError(message: Localized.prefillError))
        }
    }

    private func fetchStates(countryCode: String, successCompletion: (() -> Void)? = nil) {
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
                successCompletion?()
        }) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isLoading = false
            strongSelf.onChange?(.unexpectedError(message: Localized.statesFetchingError))
        }
    }

    private func update(with domainContactInformation: DomainContactInformation) {
        updateAddressSection(with: domainContactInformation)
        updatePhoneSection(with: domainContactInformation)
        updateContactInformationSection(with: domainContactInformation)
    }

    private func updateAddressSection(with domainContactInformation: DomainContactInformation) {
        let section = sections[SectionIndex.address.rawValue]
        section.rows[safe: addressSectionIndexHelper.cityIndex]?.editableRow?.value = domainContactInformation.city
        section.rows[safe: addressSectionIndexHelper.postalCodeIndex]?.editableRow?.value = domainContactInformation.postalCode
        section.rows[safe: addressSectionIndexHelper.addressLine1]?.editableRow?.value = domainContactInformation.address1
        section.rows[safe: addressSectionIndexHelper.stateIndex]?.editableRow?.idValue = domainContactInformation.state
        section.rows[safe: addressSectionIndexHelper.stateIndex]?.editableRow?.value = states?.filter {
            return $0.code == domainContactInformation.state
            }.first?.name
    }

    private func updatePhoneSection(with domainContactInformation: DomainContactInformation) {
        let section = sections[SectionIndex.phone.rawValue]
        if let phone = domainContactInformation.phone {
            let phoneNumberParts = phone.replacingOccurrences(of: Constant.phoneNumberCountryCodePrefix, with: "").split(separator: Constant.phoneNumberConnectingChar)
            if phoneNumberParts.count == 2 {
                section.rows[safe: CellIndex.PhoneNumber.countryCode.rawValue]?.editableRow?.value = String(phoneNumberParts[safe: 0] ?? "")
                section.rows[safe: CellIndex.PhoneNumber.number.rawValue]?.editableRow?.value = String(phoneNumberParts[safe: 1] ?? "")
            }
        }
    }

    private func updateContactInformationSection(with domainContactInformation: DomainContactInformation) {
        let section = sections[SectionIndex.contactInformation.rawValue]
        section.rows[safe: CellIndex.ContactInformation.country.rawValue]?.editableRow?.idValue = domainContactInformation.countryCode
        section.rows[safe: CellIndex.ContactInformation.country.rawValue]?.editableRow?.value = countries?.filter {
            return $0.code == domainContactInformation.countryCode
            }.first?.name
        section.rows[safe: CellIndex.ContactInformation.email.rawValue]?.editableRow?.value = domainContactInformation.email
        section.rows[safe: CellIndex.ContactInformation.firstName.rawValue]?.editableRow?.value = domainContactInformation.firstName
        section.rows[safe: CellIndex.ContactInformation.lastName.rawValue]?.editableRow?.value = domainContactInformation.lastName
        section.rows[safe: CellIndex.ContactInformation.organization.rawValue]?.editableRow?.value = domainContactInformation.organization
    }

    private func prefillCountryCodePrefix(countryCode: String) {
        let phoneSection = sections[SectionIndex.phone.rawValue]
        let countryCodeRow = phoneSection.rows[CellIndex.PhoneNumber.countryCode.rawValue].editableRow

        if let prefix = countryCodePrefix(for: countryCode),
            let countryCodeRow = countryCodeRow {
            countryCodeRow.value = prefix
        }
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

        let strippedCountryCode = countryCode
            .replacingOccurrences(of: Constant.phoneNumberCountryCodePrefix, with: "")
            .replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
        // theoretically speaking, users shouldn't be able to input "+" in that field. however, external and non-system keyboards
        // make it a _very_ theoretical thing, so we have to safe-guard it.
        // in some countries, people are used to typing a (semi-arbitrary) amount of leading zeroes before the country code.
        // we're going to take care of those too.

        let number = section.rows[CellIndex.PhoneNumber.number.rawValue].editableRow?.value ?? ""

        return Constant.phoneNumberCountryCodePrefix + strippedCountryCode +
            String(Constant.phoneNumberConnectingChar) + number
    }
}

// MARK: - Validate remotely

extension RegisterDomainDetailsViewModel {

    fileprivate func validateRemotely(successCompletion: @escaping () -> Void) {
        registerDomainDetailsService.validateDomainContactInformation(
            contactInformation: jsonRepresentation(),
            domainNames: [domain.domainName],
            success: { [weak self] (response) in
                guard let strongSelf = self else {
                    return
                }

                if response.success && !response.hasMessages {
                    strongSelf.clearValidationErrors()
                    strongSelf.onChange?(.remoteValidationFinished)
                    successCompletion()
                } else {
                    strongSelf.isLoading = false
                    WPAnalytics.track(.automatedTransferCustomDomainContactInfoValidationFailed)
                    strongSelf.updateValidationErrors(with: response.messages)
                    strongSelf.onChange?(.remoteValidationFinished)
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
                        forContext: ValidationRule.Context.serverSide
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
                forContext: .serverSide
                )?.isValid = isValid
        }
    }

    fileprivate func updateContactInformationValidationErrors(messages: ValidateDomainContactInformationResponse.Messages) {
        let rows = sections[SectionIndex.contactInformation.rawValue].rows
        for (index, row) in rows.enumerated() {
            if let rule = row.editableRow?.firstRule(forContext: .serverSide),
                let cellIndex = CellIndex.ContactInformation(rawValue: index) {
                let serverSideErrorMessage = messages.serverSideErrorMessage(for: cellIndex)
                update(rule: rule, with: serverSideErrorMessage)
            }
        }
    }

    fileprivate func updateAddressSectionValidationErrors(messages: ValidateDomainContactInformationResponse.Messages) {
        let rows = sections[SectionIndex.address.rawValue].rows
        for (index, row) in rows.enumerated() {
            if let rule = row.editableRow?.firstRule(forContext: .serverSide) {
                let addressField = addressSectionIndexHelper.addressField(for: index)
                let serverSideErrorMessage = messages.serverSideErrorMessage(addressField: addressField)
                update(rule: rule, with: serverSideErrorMessage)
            }
        }
    }

    fileprivate func update(rule: ValidationRule, with serverSideErrorMessage: String?) {
        rule.isValid = (serverSideErrorMessage == nil)
        rule.serverSideErrorMessage = serverSideErrorMessage
    }
}

extension ValidateDomainContactInformationResponse.Messages {

    typealias ContactInformation = RegisterDomainDetailsViewModel.CellIndex.ContactInformation
    typealias AddressField = RegisterDomainDetailsViewModel.CellIndex.AddressField
    typealias PhoneNumber = RegisterDomainDetailsViewModel.CellIndex.PhoneNumber

    func serverSideErrorMessage(for index: ContactInformation) -> String? {
        switch index {
        case .country:
            return countryCode?.first
        case .email:
            return email?.first
        case .firstName:
            return firstName?.first
        case .lastName:
            return lastName?.first
        case .organization:
            return organization?.first
        }
    }

    func isValidPhoneNumber() -> Bool {
        return phone?.isEmpty ?? true
    }

    func serverSideErrorMessage(addressField: AddressField) -> String? {
        switch addressField {
        case .addressLine1:
            return address1?.first
        case .addressLine2:
            return address2?.first
        case .city:
            return city?.first
        case .postalCode:
            return postalCode?.first
        case .state:
            return state?.first
        default:
            return nil
        }
    }

}
