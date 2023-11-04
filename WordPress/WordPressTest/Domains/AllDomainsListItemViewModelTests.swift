import XCTest

@testable import WordPress

final class AllDomainsListItemViewModelTests: XCTestCase {

    func testMappingWithDefaultInput() throws {
        self.testMapping(
            domain: try .make(),
            expectedViewModel: .make()
        )
    }

    func testMappingWithDomainOnlySite() throws {
        self.testMapping(
            domain: try .make(isDomainOnlySite: true),
            expectedViewModel: .make(description: nil)
        )
    }

    func testMappingWithEmptyBlogNameDomain() throws {
        self.testMapping(
            domain: try .make(blogName: ""),
            expectedViewModel: .make(description: Domain.Defaults.siteSlug)
        )
    }

    func testMappingWithUnregisteredDomain() throws {
        self.testMapping(
            domain: try .make(hasRegistration: false),
            expectedViewModel: .make(expiryDate: nil)
        )
    }

    func testMappingWithValidDomain() throws {
        let futureDate = Date.init(timeIntervalSinceNow: 365 * 24 * 60 * 60)
        let iso8601Date: String = {
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: futureDate)
        }()
        let humanReadableDate = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: futureDate)
        }()
        self.testMapping(
            domain: try .make(expiryDate: iso8601Date),
            expectedViewModel: .make(expiryDate: "Renews \(humanReadableDate)")
        )
    }

    func testMappingWithSiteRedirectDomain() throws {
        let expectedURL = URL(string: "\(ViewModel.domainManagementBasePath)/example1.com/redirect/exampleblog1.wordpress.com")
        self.testMapping(
            domain: try .make(type: "redirect"),
            expectedViewModel: .make(wpcomDetailsURL: expectedURL)
        )
    }

    func testMappingWithTransferDomain() throws {
        let expectedURL = URL(string: "\(ViewModel.domainManagementBasePath)/example1.com/transfer/in/exampleblog1.wordpress.com")
        self.testMapping(
            domain: try .make(type: "transfer"),
            expectedViewModel: .make(wpcomDetailsURL: expectedURL)
        )
    }

    private func testMapping(domain: Domain, expectedViewModel: ViewModel) {
        XCTAssertEqual(ViewModel(domain: domain), expectedViewModel)
    }
}

// MARK: - ViewModel Helpers

extension AllDomainsListItemViewModel: Equatable {

    static let domainManagementBasePath = "https://wordpress.com/domains/manage/all"

    fileprivate static func make(
        name: String = "example1.com",
        description: String? = "Example Blog 1",
        status: DomainStatus = .init(value: "Active", type: .success),
        expiryDate: String? = "Expired 1 Jan 2023",
        wpcomDetailsURL: URL? = URL(string: "\(domainManagementBasePath)/example1.com/edit/exampleblog1.wordpress.com")
    ) -> Self {
        return .init(
            name: name,
            description: description,
            status: status,
            expiryDate: expiryDate,
            wpcomDetailsURL: wpcomDetailsURL
        )
    }

    static public func ==(left: AllDomainsListItemViewModel, right: AllDomainsListItemViewModel) -> Bool {
        return left.name == right.name
        && left.description == right.description
        && left.expiryDate == right.expiryDate
        && left.status?.value == right.status?.value
        && left.status?.type == right.status?.type
        && left.wpcomDetailsURL == right.wpcomDetailsURL
    }
}

fileprivate typealias Domain = DomainsService.AllDomainsListItem
fileprivate typealias DomainStatus = Domain.Status
fileprivate typealias ViewModel = AllDomainsListItemViewModel
