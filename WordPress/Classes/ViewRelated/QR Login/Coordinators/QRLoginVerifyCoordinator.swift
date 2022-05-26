import Foundation

protocol QRLoginVerifyView {
}
class QRLoginVerifyCoordinator {
    private let parentCoordinator: QRLoginCoordinator
    private let view: QRLoginVerifyView
    private let loginCode: String
    private var state: ViewState = .verifyingCode

    init(loginCode: String, view: QRLoginVerifyView, parentCoordinator: QRLoginCoordinator) {
        self.loginCode = loginCode
        self.view = view
        self.parentCoordinator = parentCoordinator
    }
}
