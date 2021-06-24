import XCTest
@testable import WordPress

class ReferrerDetailsViewModelTests: XCTestCase {
    var sut: ReferrerDetailsViewModel!

    override func setUpWithError() throws {
        let firstChildRow = StatsTotalRowData(name: "Child 1", data: "Child data 1", disclosureURL: URL(string: "https://www.firstchild.com"))
        let secondChildRow = StatsTotalRowData(name: "Child 2", data: "Child data 2", disclosureURL: URL(string: "https://www.secondchild.com"))
        let data = StatsTotalRowData(name: "parent", data: "Data", disclosureURL: URL(string: "https://www.parent.com"), childRows: [firstChildRow, secondChildRow], isReferrerSpam: true)
        let delegate = ViewModelDelegate()
        sut = ReferrerDetailsViewModel(data: data, delegate: delegate)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testTitleInitialState() {
        XCTAssertEqual(sut.title, "parent")
    }

    func testUpdateTitleWithNewData() {
        let newData = StatsTotalRowData(name: "Some other name", data: "Some other data")
        sut.update(with: newData)

        XCTAssertEqual(sut.title, "Some other name")
    }

    func testInitialLoadingState() {
        XCTAssertFalse(sut.isLoading)
    }

    func testSetLoadingState() {
        sut.setLoadingState(true)
        XCTAssertTrue(sut.isLoading)
    }

    func testNumberOfSections() {
        XCTAssertEqual(sut.tableViewModel.sections.count, 2)
    }

    func testNumberOfSectionsWithNoURL() {
        let newData = StatsTotalRowData(name: "Some new name", data: "Some new data")

        sut.update(with: newData)

        XCTAssertEqual(sut.tableViewModel.sections.count, 1)
    }

    func testNumberOfSectionsWithNoChildren() {
        let newData = StatsTotalRowData(name: "Some new name", data: "Some new data", disclosureURL: URL(string: "https://www.somenewname.com"))

        sut.update(with: newData)

        XCTAssertEqual(sut.tableViewModel.sections.count, 1)
    }

    func testTableViewModelHeaderRow() {
        XCTAssert(sut.tableViewModel.rowAtIndexPath(IndexPath(row: 0, section: 0)) is ReferrerDetailsHeaderRow)
    }

    func testFirstDetailsRowIsValid() {
        guard let firstRow = sut.tableViewModel.rowAtIndexPath(IndexPath(row: 1, section: 0)) as? ReferrerDetailsRow else {
            XCTFail("Expected first ReferrerDetailsRow")
            return
        }
        XCTAssertFalse(firstRow.isLast)
        XCTAssertEqual(firstRow.data.name, "Child 1")
    }

    func testSecondDetailsRowIsValid() {
        guard let secondRow = sut.tableViewModel.rowAtIndexPath(IndexPath(row: 2, section: 0)) as? ReferrerDetailsRow else {
            XCTFail("Expected first ReferrerDetailsRow")
            return
        }
        XCTAssertTrue(secondRow.isLast)
        XCTAssertEqual(secondRow.data.name, "Child 2")
    }

    func testActionRowIsValid() {
        guard let actionRow = sut.tableViewModel.rowAtIndexPath(IndexPath(row: 0, section: 1)) as? ReferrerDetailsSpamActionRow else {
            XCTFail("Expected ReferrerDetailsSpamActionRow")
            return
        }

        XCTAssertTrue(actionRow.isSpam)
    }
}

private extension ReferrerDetailsViewModelTests {
    class ViewModelDelegate: ReferrerDetailsViewModelDelegate {
        func displayWebViewWithURL(_ url: URL) {
            /* not implemented */
        }

        func toggleSpamState(for referrerDomain: String, currentValue: Bool) {
            /* not implemented */
        }
    }
}
