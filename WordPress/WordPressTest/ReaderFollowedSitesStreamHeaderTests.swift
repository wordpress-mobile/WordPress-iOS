//
//  ReaderFollowedSitesStreamHeader.swift
//  WordPressTest
//
//  Created by Cesar Tardaguila on 21/2/2018.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest
@testable import WordPress

final class ReaderFollowedSitesStreamHeaderTests: XCTestCase {
    private var subject: ReaderFollowedSitesStreamHeader?
    
    private struct TestConstants {
        static let label = "Manage"
        static let hint = "Tapping lets you manage the sites you follow."
        static let traits = UIAccessibilityTraitButton
    }
    
    override func setUp() {
        super.setUp()
        subject = Bundle.loadRootViewFromNib(type: ReaderFollowedSitesStreamHeader.self)
    }
    
    override func tearDown() {
        subject = nil
        super.tearDown()
    }
    
    func testSubjectIsAccesibilityElement() {
        XCTAssertTrue(subject?.isAccessibilityElement ?? false, "ReaderFollowedSitesStreamHeader should be an accessibility element")
    }
    
    func testSubjectLabeMatchesExpectation() {
        XCTAssertEqual(subject?.accessibilityLabel, TestConstants.label, "Accessibility label does not return the expected value")
    }
    
    func testSubjectHintMatchesExpectation() {
        XCTAssertEqual(subject?.accessibilityHint, TestConstants.hint, "Accessibility hint does not return the expected value")
    }
    
    func testSubjectTraitsMatchesExpectation() {
        XCTAssertEqual(subject?.accessibilityTraits, TestConstants.traits, "Accessibility traits do not return the expected value")
    }
}
