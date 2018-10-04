//
//  SaaS-evaluation-failing-unit-tests.swift
//  WordPressTest
//
//  Created by Andrew Machen on 10/09/2018.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

final class SaaS_evaluation_failing_unit_tests: XCTestCase {
    
    func test_failingUnitTestWithoutMessage() {

        XCTFail()
    }

    func test_failingUnitTestWithMessage() {

        XCTFail("SaaS evaulation unit test with message")
    }
}
