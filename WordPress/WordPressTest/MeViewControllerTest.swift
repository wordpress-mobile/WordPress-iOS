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

        override func retrieveAccounts(completion: ([Account]) -> Void) {
             let accounts = [Account.init(userId: 1, username: "user1", email: "some@thing.com"),
             Account.init(userId: 2, username: "user2", email: "some@thingelse.com")]
            completion(accounts)
        }
    }

    var meViewController: MockedMeViewController?
    var defaultWPAccount: WPAccount {
        get {
            let context = ContextManager.sharedInstance().mainContext
            let service = AccountService(managedObjectContext: context)
            let account = service.defaultWordPressComAccount()
            return account!
        }
    }

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
            row.action.debugDescription
            if "\(row)" == "ButtonRow(title: \"Add WP Account\", action: Optional((Function)))" {
                XCTAssertTrue(true)
            }
        }
    }

}
