import XCTest

@testable import WordPress

fileprivate typealias Domain = DomainsService.AllDomainsListItem
fileprivate typealias DomainStatus = Domain.Status
fileprivate typealias ViewModel = AllDomainsListItemViewModel

final class AllDomainsListItemViewModelTests: XCTestCase {

    func testMappingWithDefaultInput() throws {
        self.assert(
            viewModelFromDomain: try .make(),
            equalTo: .make()
        )
    }

    func testMappingWithDomainOnlySite() throws {
        self.assert(
            viewModelFromDomain: try .make(isDomainOnlySite: true),
            equalTo: .make(description: nil)
        )
    }

    func testMappingWithEmptyBlogNameDomain() throws {
        self.assert(
            viewModelFromDomain: try .make(blogName: ""),
            equalTo: .make(description: Domain.Defaults.siteSlug)
        )
    }

    func testMappingWithUnregisteredDomain() throws {
        self.assert(
            viewModelFromDomain: try .make(hasRegistration: false),
            equalTo: .make(expiryDate: nil)
        )
    }

    func testMappingWithValidDomain() throws {
        let futureDate = Date.init(timeIntervalSinceNow: 365 * 24 * 60 * 60)
        let iso8601Date = ViewModel.DateFormatters.iso8601.string(from: futureDate)
        let humanReadableDate = ViewModel.DateFormatters.humanReadable.string(from: futureDate)
        self.assert(
            viewModelFromDomain: try .make(expiryDate: iso8601Date),
            equalTo: .make(expiryDate: "Renews \(humanReadableDate)")
        )
    }

    func testMappingWithSiteRedirectDomain() throws {
        let expectedURL = URL(string: "\(ViewModel.domainManagementBasePath)/example1.com/redirect/exampleblog1.wordpress.com")
        self.assert(
            viewModelFromDomain: try .make(type: "redirect"),
            equalTo: .make(wpcomDetailsURL: expectedURL)
        )
    }

    func testMappingWithTransferDomain() throws {
        let expectedURL = URL(string: "\(ViewModel.domainManagementBasePath)/example1.com/transfer/in/exampleblog1.wordpress.com")
        self.assert(
            viewModelFromDomain: try .make(type: "transfer"),
            equalTo: .make(wpcomDetailsURL: expectedURL)
        )
    }

    private func assert(viewModelFromDomain domain: Domain, equalTo viewModel: ViewModel) {
        XCTAssertEqual(ViewModel(domain: domain), viewModel)
    }
}

// MARK: - ViewModel Helpers

fileprivate extension AllDomainsListItemViewModel {

    enum DateFormatters {
        static let iso8601 = ISO8601DateFormatter()
        static let humanReadable: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()
    }

    static let domainManagementBasePath = "https://wordpress.com/domains/manage/all"

    static func make(
        name: String = "example1.com",
        description: String? = "Example Blog 1",
        status: DomainStatus = .init(value: "Active", type: .success),
        expiryDate: String? = Self.defaultExpiryDate(),
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

    private static func defaultExpiryDate() -> String? {
        guard let input = Domain.Defaults.expiryDate, let date = DateFormatters.iso8601.date(from: input) else {
            return nil
        }
        let formatted = DateFormatters.humanReadable.string(from: date)
        return "Expired \(formatted)"
    }
}

extension AllDomainsListItemViewModel: Equatable {

    static public func ==(left: AllDomainsListItemViewModel, right: AllDomainsListItemViewModel) -> Bool {
        return left.name == right.name
        && left.description == right.description
        && left.expiryDate == right.expiryDate
        && left.status?.value == right.status?.value
        && left.status?.type == right.status?.type
        && left.wpcomDetailsURL == right.wpcomDetailsURL
    }
}
