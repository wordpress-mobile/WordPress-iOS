import XCTest

@testable import WordPress

final class DomainDetailsWebViewControllerTests: XCTestCase {

    // MARK: - Types

    private typealias Domain = DomainsService.AllDomainsListItem

    private enum Constants {
        static let domainManagementBase = "https://wordpress.com/domains/manage/all"
        static let domain = Domain.Defaults.domain
        static let siteSlug = Domain.Defaults.siteSlug
        static let type = DomainType.mapped
        static let viewSlug = "edit"
    }

    // MARK: - Tests

    func testURLWithDomainOfTypeMapped() {
        XCTAssertEqual(try makeURL(type: .mapped), try makeExpectedURL(viewSlug: "edit"))
    }

    func testURLWithDomainOfTypeWpcom() {
        XCTAssertEqual(try makeURL(type: .wpCom), try makeExpectedURL(viewSlug: "edit"))
    }

    func testURLWithDomainOfTypeRegistered() {
        XCTAssertEqual(try makeURL(type: .registered), try makeExpectedURL(viewSlug: "edit"))
    }

    func testURLWithDomainOfTypeTransfer() {
        XCTAssertEqual(try makeURL(type: .transfer), try makeExpectedURL(viewSlug: "transfer/in"))
    }

    func testURLWithDomainOfTypeSiteRedirect() {
        XCTAssertEqual(try makeURL(type: .siteRedirect), try makeExpectedURL(viewSlug: "redirect"))
    }

    // MARK: - Helpers

    private func makeURL(
        domain: String = Constants.domain,
        siteSlug: String = Constants.siteSlug,
        type: DomainType = Constants.type
    ) throws -> String {
        let controller = DomainDetailsWebViewController(domain: domain, siteSlug: siteSlug, type: type)
        return try XCTUnwrap(controller.url?.absoluteString)
    }

    private func makeExpectedURL(
        domain: String = Constants.domain,
        siteSlug: String = Constants.siteSlug,
        viewSlug: String = Constants.viewSlug
    ) throws -> String {
        let url = "\(Constants.domainManagementBase)/\(domain)/\(viewSlug)/\(siteSlug)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return try XCTUnwrap(url)
    }

}
