import XCTest
@testable import WordPress

class StatsTotalRowDataTests: XCTestCase {
    var sut: StatsTotalRowData!

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testHasIcon() {
        sut = StatsTotalRowData(name: "", data: "", icon: UIImage(), socialIconURL: nil, userIconURL: nil)
        XCTAssertTrue(sut.hasIcon)

        sut = StatsTotalRowData(name: "", data: "", icon: nil, socialIconURL: URL(string: "https://www.socialIconURL.com"), userIconURL: nil)
        XCTAssertTrue(sut.hasIcon)

        sut = StatsTotalRowData(name: "", data: "", icon: nil, socialIconURL: nil, userIconURL: URL(string: "https://www.userIconURL.com"))
        XCTAssertTrue(sut.hasIcon)

        sut = StatsTotalRowData(name: "", data: "", icon: nil, socialIconURL: nil, userIconURL: nil)
        XCTAssertFalse(sut.hasIcon)
    }

    func testCanMarkReferrerAsSpam() {
        sut = StatsTotalRowData(name: "test.com", data: "", disclosureURL: URL(string: "https://www.test.com"))
        XCTAssertTrue(sut.canMarkReferrerAsSpam)

        sut = StatsTotalRowData(name: "test.com", data: "", disclosureURL: nil)
        XCTAssertTrue(sut.canMarkReferrerAsSpam)

        sut = StatsTotalRowData(name: "A Test", data: "", disclosureURL: URL(string: "https://www.test.com"))
        XCTAssertFalse(sut.canMarkReferrerAsSpam)

        sut = StatsTotalRowData(name: "A Tame", data: "", disclosureURL: nil)
        XCTAssertFalse(sut.canMarkReferrerAsSpam)
    }
}
