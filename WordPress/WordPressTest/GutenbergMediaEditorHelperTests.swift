import UIKit
import XCTest
import Nimble
import MediaEditor

@testable import WordPress

class GutenbergMediaEditorHelperTests: XCTestCase {

    func testRequestTheImageFromAGivenPHAsset() {
        let viewController = UIViewController()
        let phImageManagerMock = PHImageManagerMock()
        let mediaEditorHelper = GutenbergMediaEditorHelper(phImageManager: phImageManagerMock)

        mediaEditorHelper.edit(asset: PHAsset(), from: viewController, onFinishEditing: { _ in })

        expect(phImageManagerMock.didCallRequestImage).to(beTrue())
        expect(phImageManagerMock.options?.deliveryMode).to(equal(.highQualityFormat))
    }

    func testCallOnFinishEditingWhenPHImageManagerDoesNotReturnAnImage() {
        let viewController = UIViewController()
        let phImageManagerMock = PHImageManagerMock()
        let mediaEditorMock = MediaEditorMock()
        let mediaEditorHelper = GutenbergMediaEditorHelper(phImageManager: phImageManagerMock, mediaEditor: mediaEditorMock)
        var didCallOnFinishEditing = false
        var returnedImage: UIImage? = UIImage()
        phImageManagerMock.imageToReturn = nil

        mediaEditorHelper.edit(asset: PHAsset(), from: viewController, onFinishEditing: { image in
            didCallOnFinishEditing = true
            returnedImage = image
        })

        expect(didCallOnFinishEditing).to(beTrue())
        expect(returnedImage).to(beNil())
    }

    func testOpenTheMediaEditorWhenPHImageManagerReturnsAnImage() {
        let viewController = UIViewController()
        let phImageManagerMock = PHImageManagerMock()
        let mediaEditorMock = MediaEditorMock()
        let mediaEditorHelper = GutenbergMediaEditorHelper(phImageManager: phImageManagerMock, mediaEditor: mediaEditorMock)
        phImageManagerMock.imageToReturn = UIImage()

        mediaEditorHelper.edit(asset: PHAsset(), from: viewController, onFinishEditing: { _ in })

        expect(mediaEditorMock.didCallEdit).to(beTrue())
    }

    func testCallOnFinishEditingWithoutImageIfUserCancelCroppingAndDismissViewController() {
        let viewController = UIViewControllerMock()
        let phImageManagerMock = PHImageManagerMock()
        let mediaEditorMock = MediaEditorMock()
        let mediaEditorHelper = GutenbergMediaEditorHelper(phImageManager: phImageManagerMock, mediaEditor: mediaEditorMock)
        phImageManagerMock.imageToReturn = UIImage()
        mediaEditorMock.imageHasBeenEdited = false
        var didCallOnFinishEditing = false
        var returnedImage: UIImage? = UIImage()

        mediaEditorHelper.edit(asset: PHAsset(), from: viewController, onFinishEditing: { image in
            didCallOnFinishEditing = true
            returnedImage = image
        })

        expect(didCallOnFinishEditing).to(beTrue())
        expect(returnedImage).to(beNil())
        expect(viewController.didCallDismiss).to(beTrue())
    }

    func testCallOnFinishEditingWithTheEditedImage() {
        let viewController = UIViewControllerMock()
        let phImageManagerMock = PHImageManagerMock()
        let mediaEditorMock = MediaEditorMock()
        let mediaEditorHelper = GutenbergMediaEditorHelper(phImageManager: phImageManagerMock, mediaEditor: mediaEditorMock)
        phImageManagerMock.imageToReturn = UIImage()
        mediaEditorMock.imageHasBeenEdited = true
        var didCallOnFinishEditing = false
        var returnedImage: UIImage?

        mediaEditorHelper.edit(asset: PHAsset(), from: viewController, onFinishEditing: { image in
            didCallOnFinishEditing = true
            returnedImage = image
        })

        expect(didCallOnFinishEditing).to(beTrue())
        expect(returnedImage).toNot(beNil())
    }

}

private class PHImageManagerMock: PHImageManager {
    var didCallRequestImage = false
    var imageToReturn: UIImage?

    var options: PHImageRequestOptions?

    override func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        self.options = options
        didCallRequestImage = true
        resultHandler(imageToReturn, nil)
        return PHImageRequestID()
    }
}

private class MediaEditorMock: MediaEditor {
    var didCallEdit = false

    var imageHasBeenEdited = false

    override func edit(_ image: UIImage, from viewController: UIViewController? = nil, callback: @escaping (UIImage?) -> ()) {
        didCallEdit = true
        callback(imageHasBeenEdited ? UIImage() : nil)
    }
}

private class UIViewControllerMock: UIViewController {
    var didCallDismiss = false

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallDismiss = true
    }
}
