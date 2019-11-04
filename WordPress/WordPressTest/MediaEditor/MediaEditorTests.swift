import XCTest
import TOCropViewController
import Nimble

@testable import MediaEditor

class MediaEditorTests: XCTestCase {

    func testGiveTheImageToCropViewController() {
        let image = UIImage()
        let mediaEditor = MediaEditor()

        mediaEditor.edit(image)

        expect(mediaEditor.cropViewController?.image).to(equal(image))
    }

}
