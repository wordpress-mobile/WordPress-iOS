@testable import WordPress
import XCTest

class RegisterDomainDetailsSectionTests: XCTestCase {

    typealias Change = RegisterDomainDetailsViewModel.Section.Change
    typealias CellIndex = RegisterDomainDetailsViewModel.CellIndex.ContactInformation

    var section: RegisterDomainDetailsViewModel.Section!
    var changeArray: [Change] = []
    var changeHandler: ((Change) -> Void)!

    override func setUp() {
        super.setUp()
        changeArray = []
        changeHandler = { [weak self] (change: Change) in
            self?.changeArray.append(change)
        }
    }

    func testUpdateWithSingleField() {
        let sectionIndex = RegisterDomainDetailsViewModel.SectionIndex.contactInformation
        let emailRowIndex = CellIndex.email.rawValue
        let emailIndexPath = CellIndex.email.indexPath
        section = RegisterDomainDetailsViewModel.Section(
            rows: RegisterDomainDetailsViewModel.contactInformationRows,
            sectionIndex: sectionIndex,
            onChange: self.changeHandler
        )

        section.updateValue("invalidEmail", at: emailRowIndex)
        XCTAssert(changeArray[0] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: emailIndexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        section.updateValue("valid@email.com", at: emailRowIndex)
        XCTAssert(changeArray[1] == Change.rowValidation(tag: .proceedSubmit,
                                                         indexPath: emailIndexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        section.updateValue("anotherValid@email.com", at: emailRowIndex)
        XCTAssert(changeArray.count == 2) //no change in validation state

        section.updateValue("invalidEmail", at: emailRowIndex)
        XCTAssert(changeArray[2] == Change.rowValidation(tag: .proceedSubmit,
                                                         indexPath: emailIndexPath,
                                                         isValid: false,
                                                         errorMessage: nil))

        section.updateValue("", at: emailRowIndex)
        XCTAssert(changeArray[3] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: emailIndexPath,
                                                         isValid: false,
                                                         errorMessage: nil))

        section.updateValue("invalidEmail", at: emailRowIndex)
        XCTAssert(changeArray[4] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: emailIndexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        section.updateValue("anotherInvalidEmail", at: emailRowIndex)
        XCTAssert(changeArray.count == 5) //no change in validation state
    }

    func testUpdateWholeSection() {
        let sectionIndex = RegisterDomainDetailsViewModel.SectionIndex.contactInformation

        section = RegisterDomainDetailsViewModel.Section(
            rows: RegisterDomainDetailsViewModel.contactInformationRows,
            sectionIndex: sectionIndex,
            onChange: self.changeHandler
        )
        section.updateValue("firstName", at: CellIndex.firstName.rawValue)
        XCTAssert(changeArray[0] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: CellIndex.firstName.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        section.updateValue("lastName", at: CellIndex.lastName.rawValue)
        XCTAssert(changeArray[1] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: CellIndex.lastName.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        section.updateValue("invalidEmail", at: CellIndex.email.rawValue)
        XCTAssert(changeArray[2] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: CellIndex.email.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        section.updateValue("valid@email.com", at: CellIndex.email.rawValue)
        XCTAssert(changeArray[3] == Change.rowValidation(tag: .proceedSubmit,
                                                         indexPath: CellIndex.email.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        section.updateValue("organization", at: CellIndex.organization.rawValue)
        XCTAssert(changeArray.count == 4) //No change since this is an optional field

        section.updateValue("447710101000", at: CellIndex.phone.rawValue)

        XCTAssert(changeArray[4] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: CellIndex.phone.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        XCTAssert(changeArray[5] == Change.rowValidation(tag: .proceedSubmit,
                                                         indexPath: CellIndex.phone.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        XCTAssert(changeArray[6] == Change.sectionValidation(tag: .proceedSubmit,
                                                             sectionIndex: sectionIndex,
                                                             isValid: true))

        section.updateValue("UK", at: CellIndex.country.rawValue)

        XCTAssert(changeArray[7] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: CellIndex.country.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        XCTAssert(changeArray[8] == Change.sectionValidation(tag: .enableSubmit,
                                                             sectionIndex: sectionIndex,
                                                             isValid: true))
    }
}
