import XCTest
import TOCropViewController
import Nimble

@testable import WordPress

class MediaEditorCropZoomRotateTests: XCTestCase {

    private let image = UIImage()

    func testIsAMediaEditorCapability() {
        let mediaEditorCrop = MediaEditorCropZoomRotate(image, onFinishEditing: { _, _ in }, onCancel: {})

        expect(mediaEditorCrop).to(beAKindOf(MediaEditorCapability.self))
    }

    func testDoNotHideNavigation() {
        let mediaEditorCrop = MediaEditorCropZoomRotate(image, onFinishEditing: { _, _ in }, onCancel: {})

        let viewController = mediaEditorCrop.viewController as? TOCropViewController

        expect(viewController?.hidesNavigationBar).to(beFalse())
    }

    func testOnDidCropToRectCallOnFinishEditing() {
        var onFinishEditingCalled = false
        let mediaEditorCrop = MediaEditorCropZoomRotate(
            image,
            onFinishEditing: { _, _ in
                onFinishEditingCalled = true
            },
            onCancel: {})
        let viewController = mediaEditorCrop.viewController as? TOCropViewController

        viewController?.delegate?.cropViewController?(viewController!, didCropTo: image, with: .zero, angle: 0)

        expect(onFinishEditingCalled).to(beTrue())
    }

    func testOnDidFinishCancelledCall() {
        var onCancelCalled = false
        let mediaEditorCrop = MediaEditorCropZoomRotate(
            image,
            onFinishEditing: { _, _ in },
            onCancel: {
                onCancelCalled = true
            }
        )
        let viewController = mediaEditorCrop.viewController as? TOCropViewController

        viewController?.delegate?.cropViewController?(viewController!, didFinishCancelled: true)

        expect(onCancelCalled).to(beTrue())
    }

    func testHideRotateCounterclockwiseButton() {
        let mediaEditorCrop = MediaEditorCropZoomRotate(image, onFinishEditing: { _, _ in }, onCancel: {})

        mediaEditorCrop.apply(styles: [.rotateCounterclockwiseButtonHidden: true])

        let viewController = mediaEditorCrop.viewController as? TOCropViewController
        expect(viewController?.toolbar.rotateCounterclockwiseButtonHidden).to(beTrue())
    }

}
