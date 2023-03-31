import XCTest

@testable import WordPress

final class WPComJetpackRemoteInstallViewModelTests: CoreDataTestCase {

    private let blogID = 101
    private let api = MockWordPressComRestApi()
    private let tracker = MockEventTracker()

    private lazy var service: PluginJetpackProxyService = {
        .init(remote: JetpackProxyServiceRemote(wordPressComRestApi: api))
    }()

    private lazy var viewModel: WPComJetpackRemoteInstallViewModel = {
        .init(service: service, tracker: tracker)
    }()

    // MARK: - Tests

    // MARK: Testing which blog types are allowed to install

    // Self-hosted + Jetpack + Logged in via WordPress.com
    func test_installJetpack_givenSelfHostedSiteWithJetpack_viaWPCom_shouldNotInstall() {
        // arrange
        let blog = makeBlog(with: .selfHostedWithJetpackViaWPCom)

        // act
        viewModel.installJetpack(for: blog, isRetry: false)

        // assert
        XCTAssertTrue(viewModel.state == .install)
    }

    // Self-hosted + No Jetpack connection or plugins at all
    func test_installJetpack_givenPureSelfHostedSite_shouldNotInstall() {
        // arrange
        let blog = makeBlog(with: .selfHostedViaSiteAddress)

        // act
        viewModel.installJetpack(for: blog, isRetry: false)

        // assert
        XCTAssertTrue(viewModel.state == .install)
    }

    func test_installJetpack_givenAtomicSite_shouldNotInstall() {
        // arrange
        let blog = makeBlog(with: .atomic)

        // act
        viewModel.installJetpack(for: blog, isRetry: false)

        // assert
        XCTAssertTrue(viewModel.state == .install)
    }

    func test_installJetpack_givenWPComSite_shouldNotInstall() {
        // arrange
        let blog = makeBlog(with: .hostedAtWPCom)

        // act
        viewModel.installJetpack(for: blog, isRetry: false)

        // assert
        XCTAssertTrue(viewModel.state == .install)
    }

    // Self-hosted + Individual plugin + Logged in via WordPress.com
    func test_installJetpack_givenSelfHostedSiteWithIndividualPlugin_viaWPCom_proceedsToInstall() {
        // arrange
        let blog = makeBlog(with: .selfHostedWithIndividualPluginViaWPCom)

        // act
        viewModel.installJetpack(for: blog, isRetry: false)

        // assert
        XCTAssertTrue(viewModel.state == .installing)
    }

    // MARK: Installation state changes

    func test_installJetpack_givenValidSite_AndRequestSucceeds_shouldUpdateStateToSuccess() {
        // arrange
        let blog = makeBlog(with: .selfHostedWithIndividualPluginViaWPCom)
        let mockResponse = String()

        // act
        viewModel.installJetpack(for: blog, isRetry: false)
        api.successBlockPassedIn?(mockResponse as AnyObject, nil) // call the success block to trigger Result.success

        // assert
        XCTAssertTrue(viewModel.state == .success)
    }

    func test_installJetpack_givenValidSite_AndRequestFails_shouldUpdateStateToFailure() {
        // arrange
        let blog = makeBlog(with: .selfHostedWithIndividualPluginViaWPCom)
        let mockError = NSError(domain: "error.domain", code: 500)

        // act
        viewModel.installJetpack(for: blog, isRetry: false)
        api.failureBlockPassedIn?(mockError, nil) // call the failure block to trigger Result.failure

        // assert
        guard case .failure(let error) = viewModel.state else {
            XCTFail("Expected a failure state")
            return
        }

        XCTAssertTrue(error.type == .unknown)
    }
}

// MARK: - Helpers

private extension WPComJetpackRemoteInstallViewModelTests {

    enum BlogType {
        case selfHostedWithIndividualPluginViaWPCom
        case selfHostedWithJetpackViaWPCom
        case selfHostedViaSiteAddress
        case atomic
        case hostedAtWPCom
    }

    class MockEventTracker: EventTracker {
        func track(_ event: WordPress.WPAnalyticsEvent) {
            // no op
        }

        func track(_ event: WordPress.WPAnalyticsEvent, properties: [AnyHashable: Any]) {
            // no op
        }
    }

    func makeBlog(with type: BlogType) -> Blog {
        var builder = BlogBuilder(mainContext)

        if type == .selfHostedViaSiteAddress {
            builder = builder.with(username: "username").with(password: "password")
        } else {
            builder = builder.withAnAccount()
        }

        // The jetpack_connection_active_plugins field is only returned from the WP.com /me/sites endpoint.
        if type == .selfHostedWithIndividualPluginViaWPCom {
            builder = builder.set(blogOption: "jetpack_connection_active_plugins", value: ["jetpack-search"])
        }

        // The jetpack_connection_active_plugins field is only returned from the WP.com /me/sites endpoint.
        if type == .selfHostedWithJetpackViaWPCom {
            builder = builder
                .withJetpack()
                .set(blogOption: "jetpack_connection_active_plugins", value: ["jetpack"])
        }

        if type == .hostedAtWPCom {
            builder = builder.isHostedAtWPcom()
        }

        if type == .atomic {
            builder = builder.with(atomic: true)
        }

        return builder.build()
    }
}
