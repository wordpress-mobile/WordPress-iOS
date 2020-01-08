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

        hub.show(image: image, at: 0)

        let firstImageCell = hub.collectionView(hub.imagesCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as? MediaEditorImageCell
        expect(firstImageCell?.imageView.image).to(equal(image))
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

        expect(hub.cancelButton.titleLabel?.text).toEventually(equal("foo"))
    }

    func testApplyLoadingLabel() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()

        hub.apply(styles: [.loadingLabel: "foo"])

        expect(hub.activityIndicatorLabel.text).to(equal("foo"))
    }

    func testWhenInPortraitShowTheCorrectToolbarAndStackViewAxis() {
        XCUIDevice.shared.orientation = .portrait
        let hub: MediaEditorHub = MediaEditorHub.initialize()

        hub.loadViewIfNeeded()

        expect(hub.horizontalToolbar.isHidden).to(beFalse())
        expect(hub.verticalToolbar.isHidden).to(beTrue())
        expect(hub.mainStackView.axis).to(equal(.vertical))
        expect(hub.mainStackView.semanticContentAttribute).to(equal(.unspecified))
    }

    func testWhenInLandscapeShowTheCorrectToolbarAndStackViewAxis() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let hub: MediaEditorHub = MediaEditorHub.initialize()

        hub.loadViewIfNeeded()

        expect(hub.horizontalToolbar.isHidden).to(beTrue())
        expect(hub.verticalToolbar.isHidden).to(beFalse())
        expect(hub.mainStackView.axis).to(equal(.horizontal))
        expect(hub.mainStackView.semanticContentAttribute).to(equal(.forceRightToLeft))
    }

    func testShowButtonWithTheCapabilityIcon() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.loadViewIfNeeded()
        let icon = UIImage()

        hub.capabilities = [("Foo", icon)]

        let capabilityCell = hub.collectionView(hub.capabilitiesCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as? MediaEditorCapabilityCell
        expect(capabilityCell?.iconButton.imageView?.image).to(equal(icon))
    }

    func testCallsDelegateWhenCapabilityIsTapped() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.loadViewIfNeeded()
        let delegateMock = MediaEditorHubDelegateMock()
        hub.delegate = delegateMock

        hub.collectionView(hub.capabilitiesCollectionView, didSelectItemAt: IndexPath(row: 1, section: 0))

        expect(delegateMock.didCallCapabilityTappedWithIndex).to(equal(1))
    }

    func testShowActivityIndicatorWhenLoadingAnImage() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.loadViewIfNeeded()

        hub.loadingImage(at: 1)

        expect(hub.activityIndicatorView.isHidden).to(beFalse())
    }

    func testDoNotShowActivityIndicatorIfImageIsNotBeingLoaded() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.availableThumbs = [0: UIImage(), 1: UIImage()]
        hub.loadViewIfNeeded()
        hub.loadingImage(at: 0)

        hub.collectionView(hub.thumbsCollectionView, didSelectItemAt: IndexPath(row: 1, section: 0))

        expect(hub.activityIndicatorView.isHidden).to(beTrue())
    }

    func testShowActivityIndicatorWhenSwipingToAnImageBeingLoaded() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.availableThumbs = [0: UIImage(), 1: UIImage()]
        hub.loadViewIfNeeded()
        hub.loadingImage(at: 1)
        hub.loadingImage(at: 0)

        hub.collectionView(hub.thumbsCollectionView, didSelectItemAt: IndexPath(row: 1, section: 0))

        expect(hub.activityIndicatorView.isHidden).to(beFalse())
    }

    func testDisableCapabilitiesWhenImageIsBeingLoaded() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.availableThumbs = [0: UIImage(), 1: UIImage()]
        hub.loadViewIfNeeded()

        hub.loadingImage(at: 0)

        expect(hub.capabilitiesCollectionView.isUserInteractionEnabled).to(beFalse())
    }

    func testHideActivityIndicatorWhenImageIsLoaded() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.availableThumbs = [0: UIImage(), 1: UIImage()]
        hub.loadViewIfNeeded()
        hub.loadingImage(at: 0)

        hub.loadedImage(at: 0)

        expect(hub.activityIndicatorView.isHidden).to(beTrue())
    }

    func testEnableCapabilitiesWhenImageIsLoaded() {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.availableThumbs = [0: UIImage(), 1: UIImage()]
        hub.loadViewIfNeeded()
        hub.loadingImage(at: 0)

        hub.loadedImage(at: 0)

        expect(hub.capabilitiesCollectionView.isUserInteractionEnabled).to(beTrue())
    }

}

private class MediaEditorHubDelegateMock: MediaEditorHubDelegate {
    var didCallCapabilityTappedWithIndex: Int?

    func capabilityTapped(_ index: Int) {
        didCallCapabilityTappedWithIndex = index
    }
}
