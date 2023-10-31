import UIKit
import XCTest

@testable import WordPress

class ReaderWelcomeBannerTests: XCTestCase {

    // Displays the Welcome Banner in a Table View
    //
    func testShouldDisplay() {
        let tableView = UITableView()
        let database = EphemeralKeyValueDatabase()

        ReaderWelcomeBanner.displayIfNeeded(in: tableView, database: database)

        XCTAssertTrue(tableView.tableHeaderView is ReaderWelcomeBanner)
    }

    // Do not display the Welcome Banner in a TableView
    func testShouldNotDisplay() {
        let tableView = UITableView()
        let database = EphemeralKeyValueDatabase()
        database.set(true, forKey: ReaderWelcomeBanner.bannerPresentedKey)

        ReaderWelcomeBanner.displayIfNeeded(in: tableView, database: database)

        XCTAssertNil(tableView.tableHeaderView)
    }
}
