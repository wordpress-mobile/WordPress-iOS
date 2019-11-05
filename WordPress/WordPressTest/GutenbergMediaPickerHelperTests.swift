import UIKit
import XCTest
import Nimble

@testable import WordPress

class GutenbergMediaPickerHelperTests: XCTestCase {

    func testDoNotDismissPicker() {
        let viewController = UIViewController()
        let post = PostBuilder().build()
        let pickerViewControllerMock = WPNavigationMediaPickerViewControllerMock()
        let mediaPickerHelper = GutenbergMediaPickerHelper(context: viewController, post: post, picker: { return pickerViewControllerMock })
        var completionBlockCalled = false

        mediaPickerHelper.presentMediaPickerFullScreen(animated: false, filter: .image, allowMultipleSelection: false, dismissAfterPicking: false) { _ in
            completionBlockCalled = true
        }
        pickerViewControllerMock.didFinishPicking()

        expect(completionBlockCalled).to(beTrue())
        expect(pickerViewControllerMock.mediaPicker.didCallDismiss).to(beFalse())
    }

    func testDismissPicker() {
        let viewController = UIViewController()
        let post = PostBuilder().build()
        let pickerViewControllerMock = WPNavigationMediaPickerViewControllerMock()
        let mediaPickerHelper = GutenbergMediaPickerHelper(context: viewController, post: post, picker: { return pickerViewControllerMock })
        var completionBlockCalled = false

        mediaPickerHelper.presentMediaPickerFullScreen(animated: false, filter: .image, allowMultipleSelection: false) { _ in
            completionBlockCalled = true
        }
        pickerViewControllerMock.didFinishPicking()

        expect(completionBlockCalled).to(beTrue())
        expect(pickerViewControllerMock.mediaPicker.didCallDismiss).to(beTrue())
    }

    func testExposesTheMediaPicker() {
        let viewController = UIViewController()
        let post = PostBuilder().build()
        let pickerViewControllerMock = WPNavigationMediaPickerViewControllerMock()
        let mediaPickerHelper = GutenbergMediaPickerHelper(context: viewController, post: post, picker: { return pickerViewControllerMock })

        mediaPickerHelper.presentMediaPickerFullScreen(animated: false, filter: .image, allowMultipleSelection: false) { _ in }
        pickerViewControllerMock.didFinishPicking()

        expect(mediaPickerHelper.pickerViewController).to(equal(pickerViewControllerMock))
    }

}

private class WPNavigationMediaPickerViewControllerMock: WPNavigationMediaPickerViewController {
    let mediaPickerMock = WPMediaPickerViewControllerMock()

    func didFinishPicking() {
        delegate?.mediaPickerController(mediaPicker, didFinishPicking: [])
    }

    override var mediaPicker: WPMediaPickerViewControllerMock {
        return mediaPickerMock
    }
}

private class WPMediaPickerViewControllerMock: WPMediaPickerViewController {
    var didCallDismiss = false

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallDismiss = true
    }
}
