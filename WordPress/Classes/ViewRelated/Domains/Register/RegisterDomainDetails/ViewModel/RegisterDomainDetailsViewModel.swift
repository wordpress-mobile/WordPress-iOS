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
        case addNewAddressLineEnabled(indexPath: IndexPath)
        case addNewAddressLineReplaced(indexPath: IndexPath)
        case checkMarkRowsUpdated(sectionIndex: Int)
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
    private(set) var domain: String?

    init(domain: String?) {
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
        guard isValid(forTag: .proceedSubmit) else {
            onChange?(.registerFailedBecauseOfValidation)
            return
        }

        //TODO call service
    }
}
