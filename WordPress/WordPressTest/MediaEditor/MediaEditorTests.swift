import XCTest
import TOCropViewController
import Nimble

@testable import WordPress

class MediaEditorTests: XCTestCase {
    private let image = UIImage()

    override class func setUp() {
        super.setUp()
        MediaEditor.capabilities = [MockCapability.self]
    }

    func testNavigationBarIsHidden() {
        let mediaEditor = MediaEditor(image)

        expect(mediaEditor.navigationBar.isHidden).to(beTrue())
    }

    func testModalTransitionStyle() {
        let mediaEditor = MediaEditor(image)

        expect(mediaEditor.modalTransitionStyle).to(equal(.crossDissolve))
    }

    func testModalPresentationStyle() {
        let mediaEditor = MediaEditor(image)

        expect(mediaEditor.modalPresentationStyle).to(equal(.fullScreen))
    }

    func testSettingStylesChangingTheCurrentShownCapability() {
        let mediaEditor = MediaEditor(image)

        mediaEditor.styles = [.doneLabel: "foo"]

        let currentCapability = mediaEditor.currentCapability as? MockCapability
        expect(currentCapability?.applyCalled).to(beTrue())
    }

    func editPresentsFromTheGivenViewController() {
        let viewController = UIViewControllerMock()
        let mediaEditor = MediaEditor(image)

        mediaEditor.edit(from: viewController, onFinishEditing: { _, _ in })

        expect(viewController.didCallPresentWith).to(equal(mediaEditor))
    }

    // WHEN: One single image + one single capability

    func testShowTheCapabilityRightAway() {
        let mediaEditor = MediaEditor(image)

        expect(mediaEditor.visibleViewController).to(equal(mediaEditor.currentCapability?.viewController))
    }

    func testWhenCancelingDismissTheMediaEditor() {
        let viewController = UIViewController()
        let mediaEditor = MediaEditor(image)
        viewController.present(mediaEditor, animated: false)

        mediaEditor.currentCapability?.onCancel()

        expect(viewController.presentedViewController).to(beNil())
    }

    func testWhenFinishEditingCallOnFinishEditing() {
        var didCallOnFinishEditing = false
        let mediaEditor = MediaEditor(image)
        mediaEditor.onFinishEditing = { _, _ in
            didCallOnFinishEditing = true
        }

        mediaEditor.currentCapability?.onFinishEditing(image, [])

        expect(didCallOnFinishEditing).to(beTrue())
    }

}

class MockCapability: MediaEditorCapability {
    var applyCalled = false

    var image: UIImage

    lazy var viewController: UIViewController = {
        return UIViewController()
    }()

    var onFinishEditing: (UIImage, [MediaEditorOperation]) -> ()

    var onCancel: (() -> ())

    required init(_ image: UIImage, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: @escaping () -> ()) {
        self.image = image
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
    }

    func apply(styles: MediaEditorStyles) {
        applyCalled = true
    }
}

private class UIViewControllerMock: UIViewController {
    var didCallPresentWith: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresentWith = viewControllerToPresent
    }
}
