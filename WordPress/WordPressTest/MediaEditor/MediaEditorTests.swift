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
        mediaEditor = MediaEditor(cropViewControllerFactory: cropViewControllerMockFactory)
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
        })

        mediaEditor.edit(image, onFinishEditing: { _, _ in })

        expect(imageToCrop).to(equal(image))
    }

    func testReturnsTheCroppedImage() {
        let originalImage = UIImage()
        let croppedImage = UIImage()
        var returnedImage: UIImage?

        mediaEditor.edit(originalImage, onFinishEditing: { croppedImage, _ in
            returnedImage = croppedImage
        })
        cropViewControllerMock.croppedImage = croppedImage

        expect(returnedImage).to(equal(croppedImage))
    }

    func testCallsOnCancelWhenUserCancel() {
        let image = UIImage()
        var onCancelCalled = false

        mediaEditor.edit(image, onFinishEditing: { _, _ in }, onCancel: {
            onCancelCalled = true
        })
        cropViewControllerMock.userCanceled()

        expect(onCancelCalled).to(beTrue())
    }

    func testDismissCropViewControllerWhenUserCancel() {
        let image = UIImage()
        mediaEditor.edit(image, onFinishEditing: { _, _ in })

        cropViewControllerMock.userCanceled()

        expect(self.cropViewControllerMock.didCallDismiss).to(beTrue())
    }

    func testPresentCropViewControllerFromAGivenUIViewController() {
        let image = UIImage()
        let viewControllerMock = UIViewControllerMock()

        mediaEditor.edit(image, from: viewControllerMock, onFinishEditing: { _, _ in })

        expect(viewControllerMock.didCallPresentWith).to(beAKindOf(TOCropViewController.self))
    }

    func testHideCounterClockwiseButton() {
        let image = UIImage()
        let viewControllerMock = UIViewControllerMock()

        mediaEditor.edit(image, from: viewControllerMock, onFinishEditing: { _, _ in })

        expect(self.cropViewControllerMock.toolbar.rotateCounterclockwiseButtonHidden).to(beTrue())
    }

    func testReturnCropOperationIfImageWasCropped() {
        let image = UIImage()
        var returnedOperations: [MediaEditorOperation]?

        mediaEditor.edit(image, onFinishEditing: { _, operations in
            returnedOperations = operations
        })
        cropViewControllerMock.crop(CGRect(x: 0, y: 0, width: 100, height: 100), angle: 0)

        expect(returnedOperations).to(equal([.crop]))
    }

    func testReturnRotateOperationIfImageWasRotated() {
        let image = UIImage()
        var returnedOperations: [MediaEditorOperation]?

        mediaEditor.edit(image, onFinishEditing: { _, operations in
            returnedOperations = operations
        })
        cropViewControllerMock.crop(.zero, angle: 90)

        expect(returnedOperations).to(equal([.rotate]))
    }

    func testReturnRotateAndCropOperationIfImageWasRotatedAndCropped() {
        let image = UIImage()
        var returnedOperations: [MediaEditorOperation]?

        mediaEditor.edit(image, onFinishEditing: { _, operations in
            returnedOperations = operations
        })
        cropViewControllerMock.crop(CGRect(x: 0, y: 0, width: 100, height: 100), angle: 90)

        expect(returnedOperations).to(equal([.crop, .rotate]))
    }

    func testDismiss() {
        let image = UIImage()
        mediaEditor.edit(image, onFinishEditing: { _, _ in })

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
