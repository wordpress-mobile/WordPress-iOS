import XCTest
import TOCropViewController
import Nimble

@testable import WordPress

class MediaEditorCropTests: XCTestCase {

    private let image = UIImage()

    func testIsAMediaEditorCapability() {
        let mediaEditorCrop = MediaEditorCrop(image, onFinishEditing: { _, _ in }, onCancel: {})

        expect(mediaEditorCrop).to(beAKindOf(MediaEditorCapability.self))
    }

    func testDoNotHideNavigation() {
        let mediaEditorCrop = MediaEditorCrop(image, onFinishEditing: { _, _ in }, onCancel: {})

        let viewController = mediaEditorCrop.viewController as? TOCropViewController

        expect(viewController?.hidesNavigationBar).to(beFalse())
    }

    func testOnDidCropToRectCallOnFinishEditing() {
        var onFinishEditingCalled = false
        let mediaEditorCrop = MediaEditorCrop(
            image,
            onFinishEditing: { _, _ in
                onFinishEditingCalled = true
            },
            onCancel: {})
        let viewController = mediaEditorCrop.viewController as? TOCropViewController

        viewController?.onDidCropToRect?(image, .zero, 0)

        expect(onFinishEditingCalled).to(beTrue())
    }

    func testOnDidFinishCancelledCall() {
        var onCancelCalled = false
        let mediaEditorCrop = MediaEditorCrop(
            image,
            onFinishEditing: { _, _ in },
            onCancel: {
                onCancelCalled = true
            }
        )
        let viewController = mediaEditorCrop.viewController as? TOCropViewController

        viewController?.onDidFinishCancelled?(true)

        expect(onCancelCalled).to(beTrue())
    }

    func testHideRotateCounterclockwiseButton() {
        let mediaEditorCrop = MediaEditorCrop(image, onFinishEditing: { _, _ in }, onCancel: {})

        mediaEditorCrop.apply(styles: [.rotateCounterclockwiseButtonHidden: true])

        let viewController = mediaEditorCrop.viewController as? TOCropViewController
        expect(viewController?.toolbar.rotateCounterclockwiseButtonHidden).to(beTrue())
    }

}
