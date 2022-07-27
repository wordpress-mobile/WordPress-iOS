//
//  DomainExpiryDateFormatterTests.swift
//  WordPressTest
//
//  Created by James Frost on 20/10/2021.
//  Copyright © 2021 WordPress. All rights reserved.
//

import XCTest
@testable import WordPress

class DomainExpiryDateFormatterTests: XCTestCase {
    typealias Localized = DomainExpiryDateFormatter.Localized

    func testDomainWithNoExpiry() {
        let domain = Domain(domainName: "mycooldomain.com",
                            isPrimaryDomain: false,
                            domainType: .registered,
                            expiryDate: nil)

        let expiryDate = DomainExpiryDateFormatter.expiryDate(for: domain)
        XCTAssertEqual(expiryDate, Localized.neverExpires)
    }

    func testAutoRenewingDomain() {
        let domain = Domain(domainName: "mycooldomain.com",
                            isPrimaryDomain: false,
                            domainType: .registered,
                            autoRenewing: true,
                            autoRenewalDate: "5th August, 2022",
                            expirySoon: false,
                            expired: false,
                            expiryDate: "4th August, 2022")

        let expiryDate = DomainExpiryDateFormatter.expiryDate(for: domain)
        let formattedString = String(format: Localized.renewsOn, domain.autoRenewalDate)

        XCTAssertEqual(expiryDate, formattedString)
    }

    func testAutoRenewingDomainWithNoDate() {
        // I think this should never happen, but it's good to cover the case anyway.
        let domain = Domain(domainName: "mycooldomain.com",
                            isPrimaryDomain: false,
                            domainType: .registered,
                            autoRenewing: true,
                            autoRenewalDate: "",
                            expirySoon: false,
                            expired: false,
                            expiryDate: "4th August, 2022")

        let expiryDate = DomainExpiryDateFormatter.expiryDate(for: domain)
        XCTAssertEqual(expiryDate, Localized.autoRenews)
    }

    func testExpiredDomain() {
        let domain = Domain(domainName: "mycooldomain.com",
                            isPrimaryDomain: false,
                            domainType: .registered,
                            autoRenewing: false,
                            autoRenewalDate: "",
                            expirySoon: false,
                            expired: true,
                            expiryDate: "4th August, 2021")

        let expiryDate = DomainExpiryDateFormatter.expiryDate(for: domain)
        XCTAssertEqual(expiryDate, Localized.expired)
    }

    func testExpiringDomain() {
        let domain = Domain(domainName: "mycooldomain.com",
                            isPrimaryDomain: false,
                            domainType: .registered,
                            expired: false,
                            expiryDate: "4th August, 2022")

        let expiryDate = DomainExpiryDateFormatter.expiryDate(for: domain)
        let formattedString = String(format: Localized.expiresOn, domain.expiryDate)

        XCTAssertEqual(expiryDate, formattedString)
    }
}
