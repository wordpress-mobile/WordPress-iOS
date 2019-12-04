import XCTest
import TOCropViewController
import Nimble

@testable import WordPress

class MediaEditorTests: XCTestCase {

    private var cropViewControllerMock: TOCropViewControllerMock!
    private var mediaEditor: MediaEditor!

    override func setUp() {
        super.setUp()
        cropViewControllerMock = TOCropViewControllerMock()
        mediaEditor = MediaEditor(cropViewControllerFactory: cropViewControllerMockFactory, image: UIImage())
    }

    override func tearDown() {
        super.tearDown()
        cropViewControllerMock = nil
        mediaEditor = nil
    }

    func testGiveTheImageToCropViewController() {
        let image = UIImage()
        var imageToCrop: UIImage?
        let mediaEditor = MediaEditor(cropViewControllerFactory: { image in
            imageToCrop = image
            return self.cropViewControllerMock
        }, image: image)

        mediaEditor.edit(onFinishEditing: { _, _ in })

        expect(imageToCrop).to(equal(image))
    }

    func testCallOnFinishEditingWhenUserTapDone() {
        var onFinishEditingCalled = false

        mediaEditor.edit(onFinishEditing: { _, _ in
            onFinishEditingCalled = true
        })
        cropViewControllerMock.userTapDone()

        expect(onFinishEditingCalled).to(beTrue())
    }

    func testCallsOnCancelWhenUserCancel() {
        var onCancelCalled = false

        mediaEditor.edit(onFinishEditing: { _, _ in }, onCancel: {
            onCancelCalled = true
        })
        cropViewControllerMock.userCanceled()

        expect(onCancelCalled).to(beTrue())
    }

    func testDismissCropViewControllerWhenUserCancel() {
        mediaEditor.edit(onFinishEditing: { _, _ in })

        cropViewControllerMock.userCanceled()

        expect(self.cropViewControllerMock.didCallDismiss).to(beTrue())
    }

    func testPresentCropViewControllerFromAGivenUIViewController() {
        let viewControllerMock = UIViewControllerMock()

        mediaEditor.edit(from: viewControllerMock, onFinishEditing: { _, _ in })

        expect(viewControllerMock.didCallPresentWith).to(beAKindOf(TOCropViewController.self))
    }

    func testReturnCropOperationIfImageWasCropped() {
        var returnedOperations: [MediaEditorOperation]?

        mediaEditor.edit(onFinishEditing: { _, operations in
            returnedOperations = operations
        })
        cropViewControllerMock.crop(CGRect(x: 0, y: 0, width: 100, height: 100), angle: 0)

        expect(returnedOperations).to(equal([.crop]))
    }

    func testReturnRotateOperationIfImageWasRotated() {
        var returnedOperations: [MediaEditorOperation]?

        mediaEditor.edit(onFinishEditing: { _, operations in
            returnedOperations = operations
        })
        cropViewControllerMock.crop(.zero, angle: 90)

        expect(returnedOperations).to(equal([.rotate]))
    }

    func testReturnRotateAndCropOperationIfImageWasRotatedAndCropped() {
        var returnedOperations: [MediaEditorOperation]?

        mediaEditor.edit(onFinishEditing: { _, operations in
            returnedOperations = operations
        })
        cropViewControllerMock.crop(CGRect(x: 0, y: 0, width: 100, height: 100), angle: 90)

        expect(returnedOperations).to(equal([.crop, .rotate]))
    }

    func testDismiss() {
        mediaEditor.edit(onFinishEditing: { _, _ in })

        mediaEditor.dismiss(animated: true)

        expect(self.cropViewControllerMock.didCallDismiss).to(beTrue())
    }

    private func cropViewControllerMockFactory(_: UIImage) -> TOCropViewController {
        return cropViewControllerMock
    }

}

private class TOCropViewControllerMock: TOCropViewController {
    var didCallDismiss: Bool?

    var _imageCropFrame: CGRect = .zero
    override var imageCropFrame: CGRect {
        get {
            return _imageCropFrame
        }

        set {
            _imageCropFrame = newValue
        }
    }

    var _angle: Int = 0
    override var angle: Int {
        get {
            return _angle
        }

        set {
            _angle = newValue
        }
    }

    var croppedImage: UIImage? {
        didSet {
            delegate?.cropViewController?(self, didCropTo: croppedImage!, with: imageCropFrame, angle: angle)
        }
    }

    func crop(_ rect: CGRect, angle: Int) {
        self.imageCropFrame = rect
        self.angle = angle
        croppedImage = UIImage()
    }

    func userCanceled() {
        delegate?.cropViewController?(self, didFinishCancelled: true)
    }

    func userTapDone() {
        croppedImage = UIImage()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallDismiss = true
    }
}

private class UIViewControllerMock: UIViewController {
    var didCallPresentWith: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresentWith = viewControllerToPresent
    }
}
