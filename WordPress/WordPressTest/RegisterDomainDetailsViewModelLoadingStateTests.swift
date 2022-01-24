@testable import WordPress
import XCTest

class RegisterDomainDetailsViewModelLoadingStateTests: XCTestCase {
    private var viewModel: RegisterDomainDetailsViewModel!

    override func setUp() {
        super.setUp()

        let domainSuggestion = try! FullyQuotedDomainSuggestion(json: ["domain_name": "" as AnyObject])
        let siteID = 9001

        viewModel = RegisterDomainDetailsViewModel(siteID: siteID, domain: domainSuggestion) { _ in return
        }
    }

    func testLoadingStateWithContactInfoValidationFailure() {
        let mockService = RegisterDomainDetailsServiceProxyMock(validateDomainContactInformationSuccess: false)
        viewModel.registerDomainDetailsService = mockService

        let waitExpectation = expectation(description: "Waiting for mock service")
        viewModel.onChange = { [weak self] change in
            switch change {
            case .unexpectedError:
                XCTAssert(self?.viewModel.isLoading == false)
                waitExpectation.fulfill()
                return
            default:
                break
            }
        }
        viewModel.register()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testLoadingStateWithContactInfoValidationResponseFailure() {
        let mockService = RegisterDomainDetailsServiceProxyMock(validateDomainContactInformationSuccess: true,
                                                                validateDomainContactInformationResponseSuccess: false)
        viewModel.registerDomainDetailsService = mockService

        let waitExpectation = expectation(description: "Waiting for mock service")
        viewModel.onChange = { [weak self] change in
            switch change {
            case .remoteValidationFinished:
                XCTAssert(self?.viewModel.isLoading == false)
                waitExpectation.fulfill()
                return
            default:
                break
            }
        }
        viewModel.register()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testLoadingStateWithContactInfoValidationResponseSuccess() {
        let mockService = RegisterDomainDetailsServiceProxyMock(validateDomainContactInformationSuccess: true,
                                                                validateDomainContactInformationResponseSuccess: true)
        viewModel.registerDomainDetailsService = mockService

        let waitExpectation = expectation(description: "Waiting for mock service")
        viewModel.onChange = { [weak self] change in
            switch change {
            case .remoteValidationFinished:
                XCTAssert(self?.viewModel.isLoading == true)
                waitExpectation.fulfill()
                return
            default:
                break
            }
        }
        viewModel.register()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testLoadingStateWithShoppingCartCreationFailure() {
        let mockService = RegisterDomainDetailsServiceProxyMock(createShoppingCartSuccess: false)
        viewModel.registerDomainDetailsService = mockService

        let waitExpectation = expectation(description: "Waiting for mock service")
        viewModel.onChange = { [weak self] change in
            switch change {
            case .prefillError:
                XCTAssert(self?.viewModel.isLoading == false)
                waitExpectation.fulfill()
                return
            default:
                break
            }
        }
        viewModel.register()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testLoadingStateWithCartRedemptionUsingCreditsFailure() {
        let mockService = RegisterDomainDetailsServiceProxyMock(redeemCartUsingCreditsSuccess: false)
        viewModel.registerDomainDetailsService = mockService

        let waitExpectation = expectation(description: "Waiting for mock service")
        viewModel.onChange = { [weak self] change in
            switch change {
            case .prefillError:
                XCTAssert(self?.viewModel.isLoading == false)
                waitExpectation.fulfill()
                return
            default:
                break
            }
        }
        viewModel.register()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testLoadingStateWithPrimaryDomainChangeFailure() {
        let mockService = RegisterDomainDetailsServiceProxyMock(changePrimaryDomainSuccess: false)
        viewModel.registerDomainDetailsService = mockService

        let waitExpectation = expectation(description: "Waiting for mock service")
        viewModel.onChange = { [weak self] change in
            switch change {
            case .prefillError:
                XCTFail()
            case .domainIsPrimary:
                XCTFail()
            case .registerSucceeded:
                XCTAssert(self?.viewModel.isLoading == false)
                waitExpectation.fulfill()
            default:
                break
            }
        }
        viewModel.register()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testLoadingStateWithRegistrationSuccess() {
        let mockService = RegisterDomainDetailsServiceProxyMock()
        viewModel.registerDomainDetailsService = mockService

        let waitExpectation = expectation(description: "Waiting for mock service")
        viewModel.onChange = { [weak self] change in
            switch change {
            case .registerSucceeded:
                XCTAssert(self?.viewModel.isLoading == false)
                waitExpectation.fulfill()
                return
            default:
                break
            }
        }
        viewModel.register()
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
