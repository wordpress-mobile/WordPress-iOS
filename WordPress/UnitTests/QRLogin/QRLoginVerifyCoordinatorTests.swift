import XCTest
@testable import WordPress

class QRLoginVerifyCoordinatorTests: CoreDataTestCase {
    let testToken = QRLoginToken(token: "", data: "")

    // MARK: - Initial Validation
    func testCoordinationStateIsSetOnInit() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        // Verify the coordinator is in the right state
        XCTAssertEqual(coordinator.state, .verifyingCode)
    }

    func testValidationRenderSuccess() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        service.responseExpectation = .success

        coordinator.start()

        // Verify the coordinator is in the right state
        XCTAssertEqual(coordinator.state, .waitingForUserVerification)

        // Check the view stack
        let expectedStack: [QRLoginVerifyViewMock.LoginState] = [.showLoading, .renderResponse]
        XCTAssertEqual(view.stateStack, expectedStack)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeDisplayed, .qrLoginVerifyCodeTokenValidated]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    func testValidationQRLoginError() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)

        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)
        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        service.responseExpectation = .failure
        coordinator.start()

        // Verify the coordinator is in the right state
        XCTAssertEqual(coordinator.state, .error)

        // Check the view stack
        let expectedStack: [QRLoginVerifyViewMock.LoginState] = [.showLoading, .showQRLoginError]
        XCTAssertEqual(view.stateStack, expectedStack)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeDisplayed, .qrLoginVerifyCodeFailed]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    func testValidationNoConnectionError() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: false)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        service.responseExpectation = .failure
        coordinator.start()

        // Verify the coordinator is in the right state
        XCTAssertEqual(coordinator.state, .error)

        // Check the view stack
        let expectedStack: [QRLoginVerifyViewMock.LoginState] = [.showLoading, .showNoConnectionError]
        XCTAssertEqual(view.stateStack, expectedStack)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeDisplayed, .qrLoginVerifyCodeFailed]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    // MARK: - Confirm Tapped when waiting for user verification

    /// Tests when the user taps the confirm button and is sucessful
    func testConfirmFromWaitingForUserVerificationAndSucceeds() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        // Configure the mocks
        coordinator.state = .waitingForUserVerification
        service.responseExpectation = .success

        // Trigger the action
        coordinator.confirm()

        // Verify the coordinator is in the right state
        XCTAssertEqual(coordinator.state, .done)

        // Check the view stack
        let expectedStack: [QRLoginVerifyViewMock.LoginState] = [.showAuthenticating, .renderCompletion]
        XCTAssertEqual(view.stateStack, expectedStack)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeApproved, .qrLoginAuthenticated]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    func testConfirmFromWaitingForUserVerificationAndFails() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        // Configure the mocks
        coordinator.state = .waitingForUserVerification
        service.responseExpectation = .failure

        // Trigger the action
        coordinator.confirm()

        // Verify the coordinator is in the right state
        XCTAssertEqual(coordinator.state, .error)

        // Check the view stack
        let expectedStack: [QRLoginVerifyViewMock.LoginState] = [.showAuthenticating, .showAuthenticationFailedError]
        XCTAssertEqual(view.stateStack, expectedStack)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeApproved, .qrLoginVerifyCodeFailed]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    func testConfirmFromWaitingForUserVerificationAndHasNoInternet() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: false)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        // Configure the mocks
        coordinator.state = .waitingForUserVerification
        service.responseExpectation = .failure

        // Trigger the action
        coordinator.confirm()

        // Verify the coordinator is in the right state
        XCTAssertEqual(coordinator.state, .error)

        // Check the view stack
        let expectedStack: [QRLoginVerifyViewMock.LoginState] = [.showAuthenticating, .showNoConnectionError]
        XCTAssertEqual(view.stateStack, expectedStack)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeApproved, .qrLoginVerifyCodeFailed]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    // MARK: - Confirm Tapped when in error/done states
    func testConfirmTappedFromErrorState() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        // Configure the mocks
        coordinator.state = .error

        // Trigger the action
        coordinator.confirm()

        // Make sure the scan again was triggered
        XCTAssertTrue(parentCoordinator.didScanAgain)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeScanAgain]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    func testConfirmTappedFromDoneState() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        // Configure the mocks
        coordinator.state = .done

        // Trigger the action
        coordinator.confirm()

        // Make sure the scan again was triggered
        XCTAssertTrue(parentCoordinator.wasDismissed)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeDismissed]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    // MARK: - Cancel Button Tapped
    func testCancelButtonTapped() {
        let view = QRLoginVerifyViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let service = QRLoginServiceMock(coreDataStack: contextManager)
        let connectionChecker = QRConnectionCheckerMock(mockConnectionAvailable: true)

        let coordinator = QRLoginVerifyCoordinator(token: testToken,
                                                   view: view,
                                                   parentCoordinator: parentCoordinator,
                                                   connectionChecker: connectionChecker,
                                                   service: service,
                                                   coreDataStack: contextManager)

        // Trigger the action
        coordinator.cancel()

        // Make sure the scan again was triggered
        XCTAssertTrue(parentCoordinator.wasDismissed)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginVerifyCodeCancelled]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }
}

private class ParentCoorinatorMock: QRLoginParentCoordinator {
    var trackStack: [WPAnalyticsEvent] = []

    func track(_ event: WPAnalyticsEvent) {
        track(event, properties: nil)
    }

    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]?) {
        trackStack.append(event)
    }

    var didScanAgain: Bool = false
    func scanAgain() {
        didScanAgain = true
    }

    var scanToken: QRLoginToken? = nil

    func didScanToken(_ token: QRLoginToken) {
        scanToken = token
    }

    var wasDismissed: Bool = false

    func dismiss() {
        wasDismissed = true
    }
}

/// Allows us to control whether the connection available state
private struct QRConnectionCheckerMock: QRLoginConnectionChecker {
    let mockConnectionAvailable: Bool

    var connectionAvailable: Bool {
        return mockConnectionAvailable
    }
}

private class QRLoginVerifyViewMock: QRLoginVerifyView {
    enum LoginState {
        case renderResponse
        case renderCompletion
        case showLoading
        case showAuthenticating
        case showNoConnectionError
        case showQRLoginError
        case showAuthenticationFailedError
    }

    var stateStack: [LoginState] = []

    func pushState(_ state: LoginState) {
        stateStack.append(state)
    }

    func render(response: QRLoginValidationResponse) {
        pushState(.renderResponse)
    }

    func renderCompletion() {
        pushState(.renderCompletion)
    }

    func showLoading() {
        pushState(.showLoading)
    }

    func showAuthenticating() {
        pushState(.showAuthenticating)
    }

    func showNoConnectionError() {
        pushState(.showNoConnectionError)
    }

    func showQRLoginError(error: QRLoginError?) {
        pushState(.showQRLoginError)
    }

    func showAuthenticationFailedError() {
        pushState(.showAuthenticationFailedError)
    }
}

private class QRLoginServiceMock: QRLoginService {
    enum ResponseExpectation {
        case success
        case failure
    }

    var responseExpectation: ResponseExpectation = .success

    override func validate(token: QRLoginToken, success: @escaping(QRLoginValidationResponse) -> Void, failure: @escaping(Error?, QRLoginError?) -> Void) {
        switch responseExpectation {
        case .success:
            let json = "{\"browser\": \"browser\",\"location\": \"location\"}"
            let data = json.data(using: .utf8) ?? Data()
            let jsonDecoder = JSONDecoder()
            let response = try? jsonDecoder.decode(QRLoginValidationResponse.self, from: data)
            guard let response = response else {
                failure(nil, .invalidData)
                return
            }

            success(response)
        case .failure:
            failure(nil, .invalidData)
        }
    }

    override func authenticate(token: QRLoginToken, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        switch responseExpectation {
        case .success:
            success(true)

        case .failure:
            failure(WordPressComRestApiError.responseSerializationFailed)
        }
    }
}
