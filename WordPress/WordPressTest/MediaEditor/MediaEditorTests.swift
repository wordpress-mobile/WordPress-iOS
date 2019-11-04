import XCTest
import TOCropViewController
import Nimble

@testable import MediaEditor

class MediaEditorTests: XCTestCase {

    func testGiveTheImageToCropViewController() {
        let image = UIImage()
        let mediaEditor = MediaEditor()

        mediaEditor.edit(image) { _ in }

        expect(mediaEditor.cropViewController?.image).to(equal(image))
    }

    func testReturnsTheCroppedImage() {
        let originalImage = UIImage()
        let croppedImage = UIImage()
        var returnedImage: UIImage?
        let mediaEditor = MediaEditor.init(cropViewControllerFactory: TOCropViewControllerMock.init)

        mediaEditor.edit(originalImage) { croppedImage in
            returnedImage = croppedImage
        }
        (mediaEditor.cropViewController as? TOCropViewControllerMock)?.croppedImage = croppedImage

        expect(returnedImage).to(equal(croppedImage))
    }

    func testReturnsNothingWhenUserCancel() {
        let image = UIImage()
        var returnedImage: UIImage?
        let mediaEditor = MediaEditor.init(cropViewControllerFactory: TOCropViewControllerMock.init)

        mediaEditor.edit(image) { croppedImage in
            returnedImage = croppedImage
        }
        (mediaEditor.cropViewController as? TOCropViewControllerMock)?.userCanceled()

        expect(returnedImage).to(beNil())
    }

    func testDismissCropViewControllerWhenUserCancel() {
        let image = UIImage()
        let mediaEditor = MediaEditor.init(cropViewControllerFactory: TOCropViewControllerMock.init)
        mediaEditor.edit(image) { _ in }
        let cropViewControllerMock = (mediaEditor.cropViewController as? TOCropViewControllerMock)

        cropViewControllerMock?.userCanceled()

        expect(cropViewControllerMock?.didCallDismiss).to(beTrue())
    }

}

class TOCropViewControllerMock: TOCropViewController {
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
