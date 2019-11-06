import UIKit
import XCTest
import Nimble

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

}

private class PHImageManagerMock: PHImageManager {
    var didCallRequestImage = false

    var options: PHImageRequestOptions?

    override func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        self.options = options
        didCallRequestImage = true
        resultHandler(nil ,nil)
        return PHImageRequestID()
    }
}
