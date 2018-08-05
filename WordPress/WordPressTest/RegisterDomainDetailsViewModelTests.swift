@testable import WordPress
import XCTest

class RegisterDomainDetailsViewModelTests: XCTestCase {
    typealias Change = RegisterDomainDetailsViewModel.Change
    typealias CellIndex = RegisterDomainDetailsViewModel.CellIndex
    typealias SectionIndex = RegisterDomainDetailsViewModel.SectionIndex
    typealias RowType = RegisterDomainDetailsViewModel.RowType
    typealias Localized = RegisterDomainDetailsViewModel.Localized
    typealias EditableKeyValueRow = RegisterDomainDetailsViewModel.Row.EditableKeyValueRow

    var viewModel: RegisterDomainDetailsViewModel!
    var changeArray: [Change] = []

    override func setUp() {
        super.setUp()
        viewModel = RegisterDomainDetailsViewModel(domain: nil)
        viewModel.onChange = { [weak self] (change: Change) in
            self?.changeArray.append(change)
        }
        changeArray = []
    }

    func testEnableAddAddressRow() {
        let initialRowCount = viewModel.sections[2].rows.count

        viewModel.enableAddAddressRow()

        XCTAssert(viewModel.sections[2].rows[1] ==
            RowType.addAddressLine(title: String(format: Localized.Address.addNewAddressLine, "\(2)"))
        )

        XCTAssert(changeArray[0] == Change.addNewAddressLineEnabled(indexPath: IndexPath.init(row: 1, section: 2)))
        XCTAssert(viewModel.sections[2].rows.count == initialRowCount + 1)

        viewModel.enableAddAddressRow()

        // we expect nothing to change
        XCTAssert(changeArray.count == 1)
        XCTAssert(viewModel.sections[2].rows.count == initialRowCount + 1)
    }

    func testReplaceAddAddressRow() {
        let initialRowCount = viewModel.sections[2].rows.count

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        XCTAssert(viewModel.sections[2].rows[1] ==
            RegisterDomainDetailsViewModel.addressLine(row: 1)
        )
        XCTAssert(changeArray[0] == Change.addNewAddressLineEnabled(indexPath: IndexPath(row: 1, section: 2)))
        XCTAssert(changeArray[1] == Change.addNewAddressLineReplaced(indexPath: IndexPath(row: 1, section: 2)))
        XCTAssert(viewModel.sections[2].rows.count == initialRowCount + 1)

        viewModel.enableAddAddressRow()

        XCTAssert(viewModel.sections[2].rows[2] ==
            RowType.addAddressLine(title: String(format: Localized.Address.addNewAddressLine, "\(3)"))
        )

        XCTAssert(changeArray[2] == Change.addNewAddressLineEnabled(indexPath: IndexPath(row: 2, section: 2)))
        XCTAssert(viewModel.sections[2].rows.count == initialRowCount + 2)

        viewModel.replaceAddNewAddressLine()

        XCTAssert(viewModel.sections[2].rows[2] ==
            RegisterDomainDetailsViewModel.addressLine(row: 2)
        )
        XCTAssert(viewModel.sections[2].rows.count == initialRowCount + 2)
        XCTAssert(changeArray[3] == Change.addNewAddressLineReplaced(indexPath: IndexPath(row: 2, section: 2)))
    }

    func testAddAddressRowMaxLimit() {
        let initialRowCount = viewModel.sections[2].rows.count

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

        XCTAssert(viewModel.sections[2].rows.count == initialRowCount + RegisterDomainDetailsViewModel.Const.maxExtraAddressLine)

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        XCTAssert(viewModel.sections[2].rows.count == initialRowCount + RegisterDomainDetailsViewModel.Const.maxExtraAddressLine)
    }

    func testEnableSubmitValidation() {

        viewModel.updateValue("firstName", at: CellIndex.ContactInformation.firstName.indexPath)
        viewModel.updateValue("lastName", at: CellIndex.ContactInformation.lastName.indexPath)
        viewModel.updateValue("valid@email.com", at: CellIndex.ContactInformation.email.indexPath)
        viewModel.updateValue("7987879879879", at: CellIndex.ContactInformation.phone.indexPath)
        viewModel.updateValue("Country", at: CellIndex.ContactInformation.country.indexPath)

        viewModel.updateValue("City", at: IndexPath(row: viewModel.addressSectionIndexHelper.cityIndex, section: SectionIndex.address.rawValue))
        viewModel.updateValue("State", at: IndexPath(row: viewModel.addressSectionIndexHelper.stateIndex, section: SectionIndex.address.rawValue))
        viewModel.updateValue("423345", at: IndexPath(row: viewModel.addressSectionIndexHelper.postalCodeIndex, section: SectionIndex.address.rawValue))
        viewModel.updateValue("address line", at: IndexPath(row: viewModel.addressSectionIndexHelper.extraAddressLineCount, section: SectionIndex.address.rawValue))

        XCTAssert(changeArray[15] == Change.wholeValidation(tag: .enableSubmit, isValid: true))

        viewModel.enableAddAddressRow()
        viewModel.replaceAddNewAddressLine()

        XCTAssert(changeArray[16] == Change.addNewAddressLineEnabled(indexPath: IndexPath(row: 1, section: 2)))
        XCTAssert(changeArray[17] == Change.addNewAddressLineReplaced(indexPath: IndexPath(row: 1, section: 2)))

        XCTAssert(viewModel.isValid(forTag: .enableSubmit))
    }
}
