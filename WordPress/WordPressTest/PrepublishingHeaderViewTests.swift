import UIKit
import Nimble

@testable import WordPress

class PrepublishingHeaderViewTests: XCTestCase {

    func testShareControllerCreated() {
        let prepublishingHeaderView = PrepublishingHeaderView.loadFromNib()
        let delegateMock = PrepublishingHeaderViewDelegateMock()
        prepublishingHeaderView.delegate = delegateMock

        prepublishingHeaderView.closeButton.sendActions(for: .touchUpInside)

        expect(delegateMock.didCallCloseButtonTapped).to(beTrue())
    }

}

class PrepublishingHeaderViewDelegateMock: PrepublishingHeaderViewDelegate {
    var didCallCloseButtonTapped = false

    func closeButtonTapped() {
        didCallCloseButtonTapped = true
    }
}
