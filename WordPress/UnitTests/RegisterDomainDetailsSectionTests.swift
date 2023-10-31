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

        section = RegisterDomainDetailsViewModel.Section(
            rows: RegisterDomainDetailsViewModel.contactInformationRows,
            sectionIndex: sectionIndex,
            onChange: self.changeHandler
        )


        //we're handling more complicated cases than just "is empty"
        section.updateValue("invalidEmail", at: emailRowIndex)
        XCTAssert(section.rows[emailRowIndex].editableRow?.isValid(inContext: .clientSide) == false)

        //nothing changes here in terms of enableSubmit rules
        section.updateValue("valid@email.com", at: emailRowIndex)
        XCTAssert(section.rows[emailRowIndex].editableRow?.isValid(inContext: .clientSide) == true)

        //empty email is invalid in terms of enableSubmit rules
        section.updateValue("", at: emailRowIndex)
        XCTAssert(section.rows[emailRowIndex].editableRow?.isValid(inContext: .clientSide) == false)

    }

    func testUpdateWholeSection() {
        let sectionIndex = RegisterDomainDetailsViewModel.SectionIndex.contactInformation

        section = RegisterDomainDetailsViewModel.Section(
            rows: RegisterDomainDetailsViewModel.contactInformationRows,
            sectionIndex: sectionIndex,
            onChange: self.changeHandler
        )

        XCTAssert(section.isValid(inContext: .clientSide) == false)

        XCTAssert(section.rows[CellIndex.firstName.rawValue].editableRow?.isValid(inContext: .clientSide) == false)
        section.updateValue("firstName", at: CellIndex.firstName.rawValue)
        XCTAssert(section.rows[CellIndex.firstName.rawValue].editableRow?.isValid(inContext: .clientSide) == true)

        XCTAssert(section.rows[CellIndex.lastName.rawValue].editableRow?.isValid(inContext: .clientSide) == false)
        section.updateValue("lastName", at: CellIndex.lastName.rawValue)
        XCTAssert(section.rows[CellIndex.lastName.rawValue].editableRow?.isValid(inContext: .clientSide) == true)

        XCTAssert(section.rows[CellIndex.email.rawValue].editableRow?.isValid(inContext: .clientSide) == false)
        section.updateValue("valid@email.com", at: CellIndex.email.rawValue)
        XCTAssert(section.rows[CellIndex.email.rawValue].editableRow?.isValid(inContext: .clientSide) == true)

        //this is an optional field so validation state does not change for this
        XCTAssert(section.rows[CellIndex.organization.rawValue].editableRow?.isValid(inContext: .clientSide) == true)
        section.updateValue("organization", at: CellIndex.organization.rawValue)
        XCTAssert(section.rows[CellIndex.organization.rawValue].editableRow?.isValid(inContext: .clientSide) == true)
        section.updateValue("", at: CellIndex.organization.rawValue) // changing it back to empty shouldn't invalidate either.
        XCTAssert(section.rows[CellIndex.organization.rawValue].editableRow?.isValid(inContext: .clientSide) == true)

        XCTAssert(section.rows[CellIndex.country.rawValue].editableRow?.isValid(inContext: .clientSide) == false)
        section.updateValue("UK", at: CellIndex.country.rawValue)
        XCTAssert(section.rows[CellIndex.country.rawValue].editableRow?.isValid(inContext: .clientSide) == true)

        XCTAssert(section.isValid(inContext: .clientSide) == true)
    }
}
