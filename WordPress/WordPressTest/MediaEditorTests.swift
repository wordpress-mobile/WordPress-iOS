import XCTest
import TOCropViewController
import Nimble

@testable import WordPress

class MediaEditorTests: XCTestCase {

    func testGiveTheImageToCropViewController() {
        let image = UIImage()
        let mediaEditor = MediaEditor()

        mediaEditor.edit(image, onFinishEditing: { _ in })

        expect(mediaEditor.cropViewController?.image).to(equal(image))
    }

    func testReturnsTheCroppedImage() {
        let originalImage = UIImage()
        let croppedImage = UIImage()
        var returnedImage: UIImage?
        let mediaEditor = MediaEditor.init(cropViewControllerFactory: TOCropViewControllerMock.init)

        mediaEditor.edit(originalImage, onFinishEditing: { croppedImage in
        returnedImage = croppedImage

        })
        (mediaEditor.cropViewController as? TOCropViewControllerMock)?.croppedImage = croppedImage

        expect(returnedImage).to(equal(croppedImage))
    }

    func testCallsOnCancelWhenUserCancel() {
        let image = UIImage()
        let mediaEditor = MediaEditor.init(cropViewControllerFactory: TOCropViewControllerMock.init)
        var onCancelCalled = false

        mediaEditor.edit(image, onFinishEditing: { _ in }, onCancel: {
            onCancelCalled = true
        })
        (mediaEditor.cropViewController as? TOCropViewControllerMock)?.userCanceled()

        expect(onCancelCalled).to(beTrue())
    }

    func testDismissCropViewControllerWhenUserCancel() {
        let image = UIImage()
        let mediaEditor = MediaEditor.init(cropViewControllerFactory: TOCropViewControllerMock.init)
        mediaEditor.edit(image, onFinishEditing: { _ in })
        let cropViewControllerMock = (mediaEditor.cropViewController as? TOCropViewControllerMock)

        cropViewControllerMock?.userCanceled()

        expect(cropViewControllerMock?.didCallDismiss).to(beTrue())
    }

    func testPresentCropViewControllerFromAGivenUIViewController() {
        let image = UIImage()
        let viewControllerMock = UIViewControllerMock()
        let mediaEditor = MediaEditor()

        mediaEditor.edit(image, from: viewControllerMock, onFinishEditing: { _ in })

        expect(viewControllerMock.didCallPresent).to(beTrue())
    }

    func testHideCounterClockwiseButton() {
        let image = UIImage()
        let viewControllerMock = UIViewControllerMock()
        let mediaEditor = MediaEditor()

        mediaEditor.edit(image, from: viewControllerMock, onFinishEditing: { _ in })

        expect(mediaEditor.cropViewController?.toolbar.rotateCounterclockwiseButtonHidden).to(beTrue())
    }

}

private class TOCropViewControllerMock: TOCropViewController {
    var didCallDismiss: Bool?

    var croppedImage: UIImage? {
        didSet {
            delegate?.cropViewController?(self, didCropTo: croppedImage!, with: .zero, angle: 0)
        }
    }

    func userCanceled() {
        delegate?.cropViewController?(self, didFinishCancelled: true)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallDismiss = true
    }
}

private class UIViewControllerMock: UIViewController {
    var didCallPresent = false

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresent = true
    }
}
