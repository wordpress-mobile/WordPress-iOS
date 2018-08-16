@testable import WordPress
import XCTest

class RegisterDomainDetailsViewModelTests: XCTestCase {
    typealias Change = RegisterDomainDetailsViewModel.Change
    typealias CellIndex = RegisterDomainDetailsViewModel.CellIndex
    typealias SectionIndex = RegisterDomainDetailsViewModel.SectionIndex
    typealias RowType = RegisterDomainDetailsViewModel.RowType
    typealias Localized = RegisterDomainDetailsViewModel.Localized
    typealias EditableKeyValueRow = RegisterDomainDetailsViewModel.Row.EditableKeyValueRow
    typealias MockData = RegisterDomainDetailsServiceProxyMock.MockData

    var viewModel: RegisterDomainDetailsViewModel!
    var changeArray: [Change] = []

    override func setUp() {
        super.setUp()
        viewModel = RegisterDomainDetailsViewModel(domain: "")
        viewModel.onChange = { [weak self] (change: Change) in
            self?.changeArray.append(change)
        }
        changeArray = []
    }

    func testEnableAddAddressRow() {
        let addressSection = viewModel.sections[SectionIndex.address.rawValue]
        let initialRowCount = addressSection.rows.count

        viewModel.registerDomainDetailsService = RegisterDomainDetailsServiceProxyMock(success: true)

        viewModel.enableAddAddressRow()
        XCTAssert(addressSection.rows[1] ==
            RowType.addAddressLine(title: String(format: Localized.Address.addNewAddressLine, "\(2)"))
        )

        XCTAssert(changeArray[0] == Change.addNewAddressLineEnabled(
            indexPath: IndexPath(row: 1, section: SectionIndex.address.rawValue))
        )
        XCTAssert(addressSection.rows.count == initialRowCount + 1)

        viewModel.enableAddAddressRow()

        // we expect nothing to change
        XCTAssert(changeArray.count == 1)
        XCTAssert(addressSection.rows.count == initialRowCount + 1)
    }

    func testReplaceAddAddressRow() {
        let addressSection = viewModel.sections[SectionIndex.address.rawValue]
        let initialRowCount = addressSection.rows.count
        viewModel.registerDomainDetailsService = RegisterDomainDetailsServiceProxyMock(success: true)

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        XCTAssert(addressSection.rows[1] ==
            RegisterDomainDetailsViewModel.addressLine(row: 1)
        )
        XCTAssert(changeArray[0] == Change.addNewAddressLineEnabled(
            indexPath: IndexPath(row: 1, section: SectionIndex.address.rawValue))
        )
        XCTAssert(changeArray[1] == Change.addNewAddressLineReplaced(
            indexPath: IndexPath(row: 1, section: SectionIndex.address.rawValue))
        )
        XCTAssert(addressSection.rows.count == initialRowCount + 1)

        viewModel.enableAddAddressRow()

        XCTAssert(addressSection.rows[2] ==
            RowType.addAddressLine(title: String(format: Localized.Address.addNewAddressLine, "\(3)"))
        )

        XCTAssert(changeArray[2] == Change.addNewAddressLineEnabled(
            indexPath: IndexPath(row: 2, section: SectionIndex.address.rawValue))
        )
        XCTAssert(addressSection.rows.count == initialRowCount + 2)

        viewModel.replaceAddNewAddressLine()

        XCTAssert(addressSection.rows[2] ==
            RegisterDomainDetailsViewModel.addressLine(row: 2)
        )
        XCTAssert(addressSection.rows.count == initialRowCount + 2)
        XCTAssert(changeArray[3] == Change.addNewAddressLineReplaced(indexPath: IndexPath(row: 2, section: SectionIndex.address.rawValue)))
    }

    func testAddAddressRowMaxLimit() {
        let addressSection = viewModel.sections[SectionIndex.address.rawValue]
        let initialRowCount = addressSection.rows.count
        viewModel.registerDomainDetailsService = RegisterDomainDetailsServiceProxyMock(success: true)

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        XCTAssert(addressSection.rows.count == initialRowCount + RegisterDomainDetailsViewModel.Const.maxExtraAddressLine)

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        XCTAssert(addressSection.rows.count == initialRowCount + RegisterDomainDetailsViewModel.Const.maxExtraAddressLine)
    }

    func testEnableSubmitValidation() {
        viewModel.registerDomainDetailsService = RegisterDomainDetailsServiceProxyMock(success: true, emptyPrefillData: true)

        viewModel.updateValue("firstName", at: CellIndex.ContactInformation.firstName.indexPath)
        viewModel.updateValue("lastName", at: CellIndex.ContactInformation.lastName.indexPath)
        viewModel.updateValue("valid@email.com", at: CellIndex.ContactInformation.email.indexPath)
        viewModel.updateValue("Country", at: CellIndex.ContactInformation.country.indexPath)

        viewModel.updateValue("90", at: CellIndex.PhoneNumber.countryCode.indexPath)
        viewModel.updateValue("1231122", at: CellIndex.PhoneNumber.number.indexPath)

        viewModel.updateValue("City", at: IndexPath(row: viewModel.addressSectionIndexHelper.cityIndex, section: SectionIndex.address.rawValue))
        viewModel.updateValue("State", at: IndexPath(row: viewModel.addressSectionIndexHelper.stateIndex, section: SectionIndex.address.rawValue))
        viewModel.updateValue("423345", at: IndexPath(row: viewModel.addressSectionIndexHelper.postalCodeIndex, section: SectionIndex.address.rawValue))
        viewModel.updateValue("address line", at: IndexPath(row: viewModel.addressSectionIndexHelper.extraAddressLineCount, section: SectionIndex.address.rawValue))

        XCTAssert(changeArray[16] == Change.wholeValidation(tag: .enableSubmit, isValid: true))

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        XCTAssert(changeArray[17] == Change.addNewAddressLineEnabled(indexPath: IndexPath(row: 1,
                                                                                          section: SectionIndex.address.rawValue)))
        XCTAssert(changeArray[18] == Change.addNewAddressLineReplaced(indexPath: IndexPath(row: 1,
                                                                                           section: SectionIndex.address.rawValue)))

        XCTAssert(viewModel.isValid(forTag: .enableSubmit))
    }

    func testPrefillData() {
        viewModel.registerDomainDetailsService = RegisterDomainDetailsServiceProxyMock(success: true, emptyPrefillData: false)

        viewModel.prefill()

        let contactInformationSection = viewModel.sections[SectionIndex.contactInformation.rawValue]
        let addressSection = viewModel.sections[SectionIndex.address.rawValue]
        let phoneSection = viewModel.sections[SectionIndex.phone.rawValue]

        XCTAssert(contactInformationSection.rows[CellIndex.ContactInformation.country.rawValue].editableRow?.jsonValue == MockData.countryCode)
        XCTAssert(contactInformationSection.rows[CellIndex.ContactInformation.country.rawValue].editableRow?.value == MockData.countryName)
        XCTAssert(contactInformationSection.rows[CellIndex.ContactInformation.email.rawValue].editableRow?.value == MockData.email)
        XCTAssert(contactInformationSection.rows[CellIndex.ContactInformation.firstName.rawValue].editableRow?.value == MockData.firstName)
        XCTAssert(contactInformationSection.rows[CellIndex.ContactInformation.lastName.rawValue].editableRow?.value == MockData.lastName)
        XCTAssert(contactInformationSection.rows[CellIndex.ContactInformation.organization.rawValue].editableRow?.value == MockData.organization)

        XCTAssert(addressSection.rows[viewModel.addressSectionIndexHelper.cityIndex].editableRow?.value == MockData.city)
        XCTAssert(addressSection.rows[viewModel.addressSectionIndexHelper.addressLine1].editableRow?.value == MockData.address1)
        XCTAssert(addressSection.rows[viewModel.addressSectionIndexHelper.postalCodeIndex].editableRow?.value == MockData.postalCode)
        XCTAssert(addressSection.rows[viewModel.addressSectionIndexHelper.stateIndex].editableRow?.jsonValue == MockData.stateCode)
        XCTAssert(addressSection.rows[viewModel.addressSectionIndexHelper.stateIndex].editableRow?.value == MockData.stateName)

        XCTAssert(phoneSection.rows[CellIndex.PhoneNumber.countryCode.rawValue].editableRow?.value == MockData.phoneCountryCode)
        XCTAssert(phoneSection.rows[CellIndex.PhoneNumber.number.rawValue].editableRow?.value == MockData.phoneNumber)
    }
}
