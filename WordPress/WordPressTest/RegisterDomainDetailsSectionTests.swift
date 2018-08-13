@testable import WordPress
import XCTest

class RegisterDomainDetailsSectionTests: XCTestCase {

    typealias Change = RegisterDomainDetailsViewModel.Section.Change
    typealias CellIndex = RegisterDomainDetailsViewModel.CellIndex.ContactInformation
    typealias Localized = RegisterDomainDetails.Localized

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
        //invalid email is also valid in terms of enableSubmit rules
        section.updateValue("invalidEmail", at: emailRowIndex)
        XCTAssert(changeArray[0] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: emailIndexPath,
                                                         isValid: true,
                                                         errorMessage: nil))
        //nothing changes here in terms of enableSubmit rules
        section.updateValue("valid@email.com", at: emailRowIndex)

        //empty email is invalid in terms of enableSubmit rules
        section.updateValue("", at: emailRowIndex)
        XCTAssert(changeArray[1] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: emailIndexPath,
                                                         isValid: false,
                                                         errorMessage: nil))
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

        section.updateValue("valid@email.com", at: CellIndex.email.rawValue)
        XCTAssert(changeArray[2] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: CellIndex.email.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        //this is an optional field so validation state does not change for this
        section.updateValue("organization", at: CellIndex.organization.rawValue)

        section.updateValue("UK", at: CellIndex.country.rawValue)

        XCTAssert(changeArray[3] == Change.rowValidation(tag: .enableSubmit,
                                                         indexPath: CellIndex.country.indexPath,
                                                         isValid: true,
                                                         errorMessage: nil))

        XCTAssert(changeArray[4] == Change.sectionValidation(tag: .enableSubmit,
                                                             sectionIndex: sectionIndex,
                                                             isValid: true))
    }
}
