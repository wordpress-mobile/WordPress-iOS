import UIKit
import Nimble

@testable import WordPress

class PrepublishingHeaderViewTests: XCTestCase {

    func testShareControllerCreated() {
        let prepublishingHeaderView = PrepublishingHeaderView.loadFromNib()
        let delegateMock = PrepublishingHeaderViewDelegateMock()
        prepublishingHeaderView.delegate = delegateMock

        prepublishingHeaderView.backButton.sendActions(for: .touchUpInside)

        expect(delegateMock.didCallBackButtonTapped).to(beTrue())
    }

}

class PrepublishingHeaderViewDelegateMock: PrepublishingHeaderViewDelegate {
    var didCallBackButtonTapped = false

    func backButtonTapped() {
        didCallBackButtonTapped = true
    }
}
