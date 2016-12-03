//
//  MeViewControllerTest.swift
//  WordPress
//
//  Created by Gonzalo G Erro on 11/14/16.
//  Copyright © 2016 WordPress. All rights reserved.
//

import XCTest
import UIKit
@testable import WordPress

class MeViewControllerTest: XCTestCase {

    class MockedMeViewController: MeViewController {

        required init() {
            super.init(style: .Grouped)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func retrieveAccounts() -> [AccountSelectionItem] {
             return  [AccountSelectionItem.init(userId: 1, username: "user1", email: "some@thing.com"),
             AccountSelectionItem.init(userId: 2, username: "user2", email: "some@thingelse.com")]
        }
    }

    var meViewController: MockedMeViewController?

    override func setUp() {
        super.setUp()
        self.meViewController = MockedMeViewController()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        self.meViewController = nil
        super.tearDown()
    }

    func testAddAccountShow() {

        let tableImmutable: ImmuTable = (meViewController?.tableViewModel(true, helpshiftBadgeCount: 0))!
        let section: ImmuTableSection = tableImmutable.sections[2]
        for row: ImmuTableRow in section.rows {
            let cell: WPTableViewCellDefault = WPTableViewCellDefault.init(style: .Value2, reuseIdentifier: "Identifier")
            row.configureCell(cell)
            let titleString = NSLocalizedString("Add WordPress.com account", comment: "Add account for WordPress.com")
            if cell.textLabel?.text == titleString {
                XCTAssertTrue(true)
            }
        }
    }
}
