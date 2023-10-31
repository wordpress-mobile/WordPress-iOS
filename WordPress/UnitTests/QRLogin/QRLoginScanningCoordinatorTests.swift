import XCTest
@testable import WordPress

class QRLoginScanningCoordinatorTests: XCTestCase {
    func testCameraPreviewIsShown() {
        let session = QRCodeScanningSessionMock()
        session.hasCamera = true
        session.previewLayer = CALayer()

        let view = QRLoginScanningViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let coordinator = QRLoginScanningCoordinator(view: view,
                                                     parentCoordinator: parentCoordinator,
                                                     cameraSession: session)

        coordinator.start()

        XCTAssertTrue(view.cameraLayerShown)
        XCTAssertTrue(session.isConfigured)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginScannerDisplayed]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    func testNoCameraErrorIsShown() {
        let session = QRCodeScanningSessionMock()
        session.hasCamera = false

        let view = QRLoginScanningViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let coordinator = QRLoginScanningCoordinator(view: view,
                                                     parentCoordinator: parentCoordinator,
                                                     cameraSession: session)

        coordinator.start()

        XCTAssertTrue(view.errorShown)
    }

    func testDidTapDismiss() {
        let session = QRCodeScanningSessionMock()
        let view = QRLoginScanningViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let coordinator = QRLoginScanningCoordinator(view: view,
                                                     parentCoordinator: parentCoordinator,
                                                     cameraSession: session)

        coordinator.didTapDismiss()

        // Verify the view was dismissed
        XCTAssertTrue(parentCoordinator.wasDismissed)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginScannerDismissed]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }

    func testDidScanToken() {
        let token = QRLoginToken(token: "", data: "")
        let session = QRCodeScanningSessionMock()
        let view = QRLoginScanningViewMock()
        let parentCoordinator = ParentCoorinatorMock()
        let coordinator = QRLoginScanningCoordinator(view: view,
                                                     parentCoordinator: parentCoordinator,
                                                     cameraSession: session)

        coordinator.didScanToken(token)

        // Verify the passed token is valid
        XCTAssertEqual(token, parentCoordinator.scanToken)

        // Verify the camera session is stopped
        XCTAssertTrue(session.isStopped)

        // Verify tracks are being recorded correctly
        let expectedTrackStack: [WPAnalyticsEvent] = [.qrLoginScannerScannedCode]
        XCTAssertEqual(parentCoordinator.trackStack, expectedTrackStack)
    }
}

// MARK: - Mocks

private class QRLoginScanningViewMock: QRLoginScanningView {
    var errorShown: Bool = false
    func showError(_ message: String) {
        errorShown = true
    }

    var cameraLayerShown: Bool = false
    func showCameraLayer(_ layer: CALayer) {
        cameraLayerShown = true
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

private class QRCodeScanningSessionMock: QRCodeScanningSession {
    var hasCamera: Bool = true
    var session: AVCaptureSession? = nil
    var previewLayer: CALayer? = nil
    weak var scanningDelegate: QRCodeScanningDelegate? = nil

    var isConfigured: Bool = false
    func configure() {
        isConfigured = true
    }

    var isStarted: Bool = false
    func start() {
        isStarted = true
    }

    var isStopped: Bool = false
    func stop() {
        isStopped = true
    }
}
