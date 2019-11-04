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

}

class TOCropViewControllerMock: TOCropViewController {
    var croppedImage: UIImage? {
        didSet {
            delegate?.cropViewController?(self, didCropTo: croppedImage!, with: .zero, angle: 0)
        }
    }
}
