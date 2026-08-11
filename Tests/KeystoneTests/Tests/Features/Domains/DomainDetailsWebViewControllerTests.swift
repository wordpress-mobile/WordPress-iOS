import XCTest
import Testing

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
        let url = "\(Constants.domainManagementBase)/\(domain)/\(viewSlug)/\(siteSlug)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return try XCTUnwrap(url)
    }
}

@MainActor
struct DomainDetailsNavigationTests {

    @Test func navigationPolicyDistinguishesRedirectsFromLinks() throws {
        let controller = DomainDetailsWebViewController(
            domain: "example.com",
            siteSlug: "example.wordpress.com",
            type: .mapped
        )
        let domainDetailsURL = try #require(controller.url)
        let redirectURL = try #require(
            URL(string: "https://wordpress.com/domains/manage/all/example.com/edit/example.wordpress.com?redirected=1")
        )
        var redirectRequest = URLRequest(url: redirectURL)
        redirectRequest.mainDocumentURL = redirectURL
        let externalURLHandler = ExternalURLHandlerSpy()

        #expect(
            DomainDetailsWebViewController.shouldAllowNavigation(
                to: redirectURL,
                domainDetailsURL: domainDetailsURL,
                isLoading: true
            )
        )
        #expect(
            DomainDetailsWebViewController.shouldAllowNavigation(
                to: domainDetailsURL,
                domainDetailsURL: domainDetailsURL,
                isLoading: false
            )
        )
        #expect(
            !DomainDetailsWebViewController.shouldAllowNavigation(
                to: redirectURL,
                domainDetailsURL: domainDetailsURL,
                isLoading: false
            )
        )

        let redirectPolicy = controller.linkBehavior.handle(
            request: redirectRequest,
            with: .other,
            externalURLHandler: externalURLHandler
        )

        #expect(redirectPolicy == .allow)
        #expect(externalURLHandler.openedURL == nil)

        let linkURL = try #require(URL(string: "https://wordpress.com/support"))
        var linkRequest = URLRequest(url: linkURL)
        linkRequest.mainDocumentURL = linkURL

        let linkPolicy = controller.linkBehavior.handle(
            request: linkRequest,
            with: .linkActivated,
            externalURLHandler: externalURLHandler
        )

        #expect(linkPolicy == .cancel)
        #expect(externalURLHandler.openedURL == linkURL)
    }
}

private final class ExternalURLHandlerSpy: ExternalURLHandler {
    private(set) var openedURL: URL?

    func open(_ url: URL) {
        openedURL = url
    }
}
