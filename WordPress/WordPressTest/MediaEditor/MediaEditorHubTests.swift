import XCTest
import Nimble

@testable import WordPress

class MediaEditorHubTests: XCTestCase {

    func testInitializeFromStoryboard() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()

        expect(hub).toNot(beNil())
    }

    func testShowImage() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        _ = hub.view
        let image = UIImage()

        hub.show(image: image)

        expect(hub.imageView.image).to(equal(image))
    }

    func testTappingCancelButtonCallsOnCancel() {
        var didCallOnCancel = false
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        _ = hub.view
        hub.onCancel = {
            didCallOnCancel = true
        }

        hub.cancelButton.sendActions(for: .touchUpInside)

        expect(didCallOnCancel).to(beTrue())
    }

    func testApplyStyles() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()

        hub.apply(styles: [.cancelLabel: "foo"])

        expect(hub.cancelButton.titleLabel?.text).to(equal("foo"))
    }

}
