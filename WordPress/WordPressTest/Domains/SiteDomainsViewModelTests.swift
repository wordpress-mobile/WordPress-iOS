import XCTest
@testable import WordPress

final class SiteDomainsViewModelTests: CoreDataTestCase {
    private var viewModel: SiteDomainsViewModel!
    private var mockDomainsService: MockDomainsService!

    override func setUp() {
        super.setUp()
        mockDomainsService = MockDomainsService()
        viewModel = SiteDomainsViewModel(blog: BlogBuilder(mainContext).build(), domainsService: mockDomainsService)
    }

    override func tearDown() {
        viewModel = nil
        mockDomainsService = nil
        super.tearDown()
    }

    func testInitialState_isLoading() {
        viewModel.refresh()
        XCTAssertTrue(viewModel.state == SiteDomainsViewModel.State.loading, "Initial state should be loading")
        XCTAssertTrue(mockDomainsService.resolveStatus)
        XCTAssertFalse(mockDomainsService.noWPCOM)
    }

    func testRefresh_onlyFreeDomain() throws {
        let blog = BlogBuilder(mainContext)
            .with(blogID: 111)
            .with(supportsDomains: true)
            .build()
        viewModel = SiteDomainsViewModel(blog: blog, domainsService: mockDomainsService)

        mockDomainsService.fetchResult = .success([try .make(domain: "Test", blogId: 111, wpcomDomain: true)])
        viewModel.refresh()

        if case .normal(let sections) = viewModel.state,
           case .rows(let rows) = sections[0].content {
            XCTAssertEqual(sections[0].title, SiteDomainsViewModel.Strings.freeDomainSectionTitle)
            XCTAssertEqual(sections[1].content, .upgradePlan)
            XCTAssertEqual(rows[0].viewModel.name, "Test")
        } else {
            XCTFail("Expected state not loaded")
        }
    }

    func testRefresh_stagingAndSimpleFreeDomain() throws {
        let blog = BlogBuilder(mainContext)
            .with(blogID: 111)
            .with(supportsDomains: true)
            .build()
        viewModel = SiteDomainsViewModel(blog: blog, domainsService: mockDomainsService)

        mockDomainsService.fetchResult = .success([
            try .make(domain: "test.wordpress.com", blogId: 111, isWpcomStagingDomain: false, wpcomDomain: true),
            try .make(domain: "test.wpcomstaging.com", blogId: 111, isWpcomStagingDomain: true, wpcomDomain: true)
        ])
        viewModel.refresh()

        if case .normal(let sections) = viewModel.state,
           case .rows(let rows) = sections[0].content {
            XCTAssertEqual(sections[0].title, SiteDomainsViewModel.Strings.freeDomainSectionTitle)
            XCTAssertEqual(sections[1].content, .upgradePlan)
            XCTAssertEqual(rows[0].viewModel.name, "test.wpcomstaging.com")
        } else {
            XCTFail("Expected state not loaded")
        }
    }

    func testRefresh_paidDomain() throws {
        let blog = BlogBuilder(mainContext)
            .with(blogID: 123)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom, domainName: "Test")
            .build()
        viewModel = SiteDomainsViewModel(blog: blog, domainsService: mockDomainsService)

        mockDomainsService.fetchResult = .success([
            try .make(blogId: 123),
            try .make(domain: "Test", blogId: 123, wpcomDomain: true)
        ])
        viewModel.refresh()

        if case .normal(let sections) = viewModel.state,
           case .rows(let secondSectionRows) = sections[1].content {
            XCTAssertEqual(secondSectionRows[0].viewModel.name, DomainsService.AllDomainsListItem.Defaults.domain)
            XCTAssertEqual(sections[2].content, .addDomain)
        } else {
            XCTFail("Expected state not loaded")
        }
    }

    func testRefresh_paidDomainForOtherBlog() throws {
        let blog = BlogBuilder(mainContext)
            .with(blogID: 123)
            .with(supportsDomains: true)
            .build()
        viewModel = SiteDomainsViewModel(blog: blog, domainsService: mockDomainsService)

        mockDomainsService.fetchResult = .success([
            try .make(blogId: 1),
            try .make(domain: "Test", blogId: 123, wpcomDomain: true)
        ])
        viewModel.refresh()

        if case .normal(let sections) = viewModel.state {
            XCTAssertEqual(sections[1].content, .upgradePlan)
        } else {
            XCTFail("Expected state not loaded")
        }
    }

    func testRefresh_error() {
        let blog = BlogBuilder(mainContext)
            .with(blogID: 123)
            .with(supportsDomains: true)
            .build()
        viewModel = SiteDomainsViewModel(blog: blog, domainsService: mockDomainsService)

        mockDomainsService.fetchResult = .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
        viewModel.refresh()

        if case .message(let message) = viewModel.state {
            XCTAssertEqual(message.title, DomainsStateViewModel.Strings.offlineEmptyStateTitle)
        } else {
            XCTFail("Expected state not loaded")
        }
    }
}

// MARK: - Helpers

private class MockDomainsService: NSObject, DomainsServiceAllDomainsFetching {
    var fetchResult: Result<[DomainsService.AllDomainsListItem], Error>?
    var resolveStatus: Bool = false
    var noWPCOM: Bool = false

    func fetchAllDomains(resolveStatus: Bool, noWPCOM: Bool, completion: @escaping (DomainsServiceRemote.AllDomainsEndpointResult) -> Void) {
        self.resolveStatus = resolveStatus
        self.noWPCOM = noWPCOM
        if let result = fetchResult {
            completion(result)
        }
    }
}

extension SiteDomainsViewModel.State: Equatable {
    public static func == (lhs: SiteDomainsViewModel.State, rhs: SiteDomainsViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.normal(let lhsSections), .normal(let rhsSections)):
            return lhsSections == rhsSections
        case (.loading, .loading):
            return true
        case (.message(let lhsMessage), .message(let rhsMessage)):
            return lhsMessage.title == rhsMessage.title
        default:
            return false
        }
    }
}

extension SiteDomainsViewModel.Section: Equatable {
    public static func == (lhs: SiteDomainsViewModel.Section, rhs: SiteDomainsViewModel.Section) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
    }
}

extension SiteDomainsViewModel.Section.SectionKind: Equatable {
    public static func == (lhs: SiteDomainsViewModel.Section.SectionKind, rhs: SiteDomainsViewModel.Section.SectionKind) -> Bool {
        switch (lhs, rhs) {
        case (.rows(let lhsRows), .rows(let rhsRows)):
            return lhsRows == rhsRows
        case (.addDomain, .addDomain), (.upgradePlan, .upgradePlan):
            return true
        default:
            return false
        }
    }
}

extension SiteDomainsViewModel.Section.Row: Equatable {
    public static func == (lhs: SiteDomainsViewModel.Section.Row, rhs: SiteDomainsViewModel.Section.Row) -> Bool {
        return lhs.id == rhs.id && lhs.viewModel == rhs.viewModel
    }
}
