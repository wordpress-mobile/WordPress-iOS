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

    func testMappingWithDomainRegisteredElsewhere() throws {
        self.assert(
            viewModelFromDomain: try .make(hasRegistration: false, expiryDate: nil),
            equalTo: .make(expiryDate: nil)
        )
    }

    func testMappingWithFreeWpComDomain() throws {
        self.assert(
            viewModelFromDomain: try .make(hasRegistration: false, expiryDate: nil, wpcomDomain: true),
            equalTo: .make(expiryDate: "Never expires")
        )
    }

    func testMappingWithMappedDomainWithExpiry() throws {
        self.assert(
            viewModelFromDomain: try .make(hasRegistration: false, expiryDate: "2099-10-17T00:00:00+00:00"),
            equalTo: .make(expiryDate: "Expires on Oct 17, 2099")
        )
    }

    // The API sends `expiry` as a midnight UTC timestamp encoding a calendar
    // date. The formatted date must preserve that calendar date; formatting in
    // a device timezone west of UTC would print Oct 16. The expected string is
    // a literal because the test plan pins the en/US locale.
    func testMappingWithValidDomain() throws {
        self.assert(
            viewModelFromDomain: try .make(expiryDate: "2099-10-17T00:00:00+00:00"),
            equalTo: .make(expiryDate: "Expires on Oct 17, 2099")
        )
    }

    private func assert(viewModelFromDomain domain: Domain, equalTo row: ViewModel.Row) {
        let viewModel = ViewModel(domain: domain)
        XCTAssertEqual(viewModel.row, row)
    }
}

// MARK: - ViewModel Helpers

fileprivate extension AllDomainsListItemViewModel.Row {

    static func make(
        name: String = "example1.com",
        description: String? = "Example Blog 1",
        status: DomainStatus = .init(value: "Active", type: .success),
        // The rendering of Domain.Defaults.expiryDate (2023-01-01T00:00:00+00:00).
        expiryDate: String? = "Expired Jan 1, 2023"
    ) -> Self {
        .init(
            name: name,
            description: description,
            status: status,
            expiryDate: expiryDate
        )
    }
}

extension AllDomainsListItemViewModel.Row: Equatable {

    static public func == (left: Self, right: Self) -> Bool {
        left.name == right.name
            && left.description == right.description
            && left.expiryDate == right.expiryDate
            && left.status?.value == right.status?.value
            && left.status?.type == right.status?.type
    }
}
