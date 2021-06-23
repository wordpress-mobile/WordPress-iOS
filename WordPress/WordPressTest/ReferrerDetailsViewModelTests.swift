import XCTest
@testable import WordPress

class ReferrerDetailsViewModelTests: XCTestCase {
    var sut: ReferrerDetailsViewModel!

    override func setUpWithError() throws {
        let data = StatsTotalRowData(name: "A name", data: "Some data")
        let delegate = ViewModelDelegate()
        sut = ReferrerDetailsViewModel(data: data, delegate: delegate)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testUpdateTitle() {
        XCTAssertEqual(sut.title, "A name")

        let newData = StatsTotalRowData(name: "Some other name", data: "Some other data")
        sut.update(with: newData)

        XCTAssertEqual(sut.title, "Some other name")
    }

    func testSetLoadingState() {
        XCTAssertFalse(sut.isLoading)

        sut.setLoadingState(true)

        XCTAssertTrue(sut.isLoading)
    }

    func testTableViewModel() {
        XCTAssertEqual(sut.tableViewModel.sections.count, 1)

        let firstChildRow = StatsTotalRowData(name: "Child 1", data: "Child data 1", disclosureURL: URL(string: "https://www.firstchild.com"))
        let secondChildRow = StatsTotalRowData(name: "Child 2", data: "Child data 2", disclosureURL: URL(string: "https://www.secondchild.com"))
        let data = StatsTotalRowData(name: "parent", data: "Data", disclosureURL: URL(string: "https://www.parent.com"), childRows: [firstChildRow, secondChildRow], isReferrerSpam: true)
        sut.update(with: data)

        XCTAssertEqual(sut.tableViewModel.sections.count, 2)
        XCTAssert(sut.tableViewModel.rowAtIndexPath(IndexPath(row: 0, section: 0)) is ReferrerDetailsHeaderRow)
        guard let firstDetailsRow = sut.tableViewModel.rowAtIndexPath(IndexPath(row: 1, section: 0)) as? ReferrerDetailsRow else {
            XCTFail("Expected first ReferrerDetailsRow")
            return
        }
        XCTAssertFalse(firstDetailsRow.isLast)
        XCTAssertEqual(firstDetailsRow.data.name, "Child 1")

        guard let secondDetailsRow = sut.tableViewModel.rowAtIndexPath(IndexPath(row: 2, section: 0)) as? ReferrerDetailsRow else {
            XCTFail("Expected first ReferrerDetailsRow")
            return
        }
        XCTAssertTrue(secondDetailsRow.isLast)
        XCTAssertEqual(secondDetailsRow.data.name, "Child 2")

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
