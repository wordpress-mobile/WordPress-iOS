import Foundation
import XCTest

@testable import WordPressKit

final class AllDomainsResultDomainTests: XCTestCase {

    // MARK: - Properties

    private let dateFormatter = ISO8601DateFormatter()

    // MARK: - Tests

    /// Tests decoding with default input defined in `Defaults` enum.
    func testDecodingWithDefaultInput() throws {
        // Given
        let decoder = makeDecoder()
        let input = try makeInput()

        // When
        let output = try decoder.decode(Domain.self, from: input)

        // Then
        let expectedOutput = makeDomain()
        assertEqual(output, otherDomain: expectedOutput)
    }

    /// Tests decoding with empty `registrationDate` and `expiryDate`.
    func testDecodingWithEmptyExpiryAndRegistrationDates() throws {
        // Given
        let decoder = makeDecoder()
        let input = try makeInput(registrationDate: "", expiryDate: nil)

        // When
        let output = try decoder.decode(Domain.self, from: input)

        // Then
        let expectedOutput = makeDomain(registrationDate: "", expiryDate: nil)
        assertEqual(output, otherDomain: expectedOutput)
    }

    /// Tests decoding with `type = mapping` and `hasRegistration = true`.
    func testDecodingWithRegistrationAndMappingType() throws {
        // Given
        let decoder = makeDecoder()
        let input = try makeInput(type: "mapping", hasRegistration: true)

        // When
        let output = try decoder.decode(Domain.self, from: input)

        // Then
        let expectedOutput = makeDomain(type: .registered, hasRegistration: true)
        assertEqual(output, otherDomain: expectedOutput)
    }

    // MARK: - Helpers

    private func assertEqual(_ domain: Domain, otherDomain: Domain) {
        XCTAssertEqual(domain.domain, otherDomain.domain)
        XCTAssertEqual(domain.blogId, otherDomain.blogId)
        XCTAssertEqual(domain.blogName, otherDomain.blogName)
        XCTAssertEqual(domain.type, otherDomain.type)
        XCTAssertEqual(domain.isDomainOnlySite, otherDomain.isDomainOnlySite)
        XCTAssertEqual(domain.isWpcomStagingDomain, otherDomain.isWpcomStagingDomain)
        XCTAssertEqual(domain.registrationDate, otherDomain.registrationDate)
        XCTAssertEqual(domain.expiryDate, otherDomain.expiryDate)
        XCTAssertEqual(domain.wpcomDomain, otherDomain.wpcomDomain)
        XCTAssertEqual(domain.currentUserIsOwner, otherDomain.currentUserIsOwner)
        XCTAssertEqual(domain.siteSlug, otherDomain.siteSlug)
        XCTAssertEqual(domain.status?.value, otherDomain.status?.value)
        XCTAssertEqual(domain.status?.type, otherDomain.status?.type)
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func makeDomain(
        domain: String = Defaults.domain,
        blogId: Int = Defaults.blogId,
        blogName: String = Defaults.blogName,
        type: DomainType = .siteRedirect,
        isDomainOnlySite: Bool = Defaults.isDomainOnlySite,
        isWpcomStagingDomain: Bool = Defaults.isWpcomStagingDomain,
        hasRegistration: Bool = Defaults.hasRegistration,
        registrationDate: String? = Defaults.registrationDate,
        expiryDate: String? = Defaults.expiryDate,
        wpcomDomain: Bool = Defaults.wpcomDomain,
        currentUserIsOwner: Bool? = Defaults.currentUserIsOwner,
        siteSlug: String = Defaults.siteSlug,
        status: DomainStatus = Defaults.status
    ) -> Domain {
        return .init(
            domain: domain,
            blogId: blogId,
            blogName: blogName,
            type: type,
            isDomainOnlySite: isDomainOnlySite,
            isWpcomStagingDomain: isWpcomStagingDomain,
            hasRegistration: hasRegistration,
            registrationDate: dateFormatter.date(from: registrationDate ?? ""),
            expiryDate: dateFormatter.date(from: expiryDate ?? ""),
            wpcomDomain: wpcomDomain,
            currentUserIsOwner: currentUserIsOwner,
            siteSlug: siteSlug,
            status: status
        )
    }

    private func makeInput(
        domain: String = Defaults.domain,
        blogId: Int = Defaults.blogId,
        blogName: String = Defaults.blogName,
        type: String = "redirect",
        isDomainOnlySite: Bool = Defaults.isDomainOnlySite,
        isWpcomStagingDomain: Bool = Defaults.isWpcomStagingDomain,
        hasRegistration: Bool = Defaults.hasRegistration,
        registrationDate: String? = Defaults.registrationDate,
        expiryDate: String? = Defaults.expiryDate,
        wpcomDomain: Bool = Defaults.wpcomDomain,
        currentUserIsOwner: Bool? = Defaults.currentUserIsOwner,
        siteSlug: String = Defaults.siteSlug,
        status: DomainStatus = Defaults.status
    ) throws -> Data {
        let json: [String: Any] = [
            "domain": domain,
            "blog_id": blogId,
            "blog_name": blogName,
            "type": type,
            "is_domain_only_site": isDomainOnlySite,
            "is_wpcom_staging_domain": isWpcomStagingDomain,
            "has_registration": hasRegistration,
            "registration_date": registrationDate as Any,
            "expiry": expiryDate as Any,
            "wpcom_domain": wpcomDomain,
            "current_user_is_owner": currentUserIsOwner as Any,
            "site_slug": siteSlug,
            "domain_status": ["status": status.value, "status_type": status.type.rawValue]
        ]
        return try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }

    private enum Defaults {
        static let domain = "example1.com"
        static let blogId: Int = 12345
        static let blogName: String = "Example Blog 1"
        static let isDomainOnlySite: Bool = false
        static let isWpcomStagingDomain: Bool = false
        static let hasRegistration: Bool = true
        static let registrationDate: String? = "2022-01-01T00:00:00+00:00"
        static let expiryDate: String? = "2023-01-01T00:00:00+00:00"
        static let wpcomDomain: Bool = false
        static let currentUserIsOwner: Bool? = false
        static let siteSlug: String = "exampleblog1.wordpress.com"
        static let status: DomainStatus = .init(value: "Active", type: .success)
    }

    typealias Domain = DomainsServiceRemote.AllDomainsListItem
    typealias DomainStatus = Domain.Status

}
