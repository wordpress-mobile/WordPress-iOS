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

    func testHubDelegate() {
        let mediaEditor = MediaEditor(image)

        let hubDelegate = mediaEditor.hub.delegate as? MediaEditor

        expect(hubDelegate).to(equal(mediaEditor))
    }

    func testGivesTheListOfCapabilitiesIconsAndNames() {
        let mediaEditor = MediaEditor(image)

        expect(mediaEditor.hub.capabilities.count).to(equal(1))
    }

    func testSettingStylesChangingTheCurrentShownCapability() {
        let mediaEditor = MediaEditor(image)

        mediaEditor.styles = [.doneLabel: "foo"]

        let currentCapability = mediaEditor.currentCapability as? MockCapability
        expect(currentCapability?.applyCalled).to(beTrue())
    }

    func testEditPresentsFromTheGivenViewController() {
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

        mediaEditor.currentCapability?.onFinishEditing(image, [.rotate])

        expect(didCallOnFinishEditing).to(beTrue())
    }

    func testWhenFinishEditingKeepRecordOfTheActions() {
        let mediaEditor = MediaEditor(image)
        mediaEditor.actions = [.crop]
        mediaEditor.onFinishEditing = { _, _ in }

        mediaEditor.currentCapability?.onFinishEditing(image, [.rotate])

        expect(mediaEditor.actions).to(equal([.crop, .rotate]))
    }

    // WHEN: Async image + one single capability

    func testRequestThumbAndFullImageQuality() {
        let asyncImage = AsyncImageMock()

        _ = MediaEditor(asyncImage)

        expect(asyncImage.didCallThumbnail).to(beTrue())
        expect(asyncImage.didCallFull).to(beTrue())
    }

    func testIfThumbnailIsAvailableShowItInHub() {
        let asyncImage = AsyncImageMock()
        asyncImage.thumb = UIImage()

        let mediaEditor = MediaEditor(asyncImage)
        UIApplication.shared.topWindow?.addSubview(mediaEditor.view)

        expect((mediaEditor.hub.imagesCollectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? MediaEditorImageCell)?.imageView.image).toEventually(equal(asyncImage.thumb))
    }

    func testDoNotRequestThumbnailIfOneIsGiven() {
        let asyncImage = AsyncImageMock()
        asyncImage.thumb = UIImage()

        _ = MediaEditor(asyncImage)

        expect(asyncImage.didCallFull).to(beTrue())
        expect(asyncImage.didCallThumbnail).to(beFalse())
    }

    func testShowActivityIndicatorWhenLoadingImage() {
        let asyncImage = AsyncImageMock()
        asyncImage.thumb = UIImage()

        let mediaEditor = MediaEditor(asyncImage)

        expect(mediaEditor.hub.activityIndicatorView.isHidden).to(beFalse())
    }

    func testWhenThumbnailIsAvailableShowItInHub() {
        let asyncImage = AsyncImageMock()
        let thumb = UIImage()
        let mediaEditor = MediaEditor(asyncImage)
        UIApplication.shared.topWindow?.addSubview(mediaEditor.view)

        asyncImage.simulate(thumbHasBeenDownloaded: thumb)

        expect((mediaEditor.hub.collectionView(mediaEditor.hub.imagesCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as? MediaEditorImageCell)?.imageView.image).toEventually(equal(thumb))
    }

    func testWhenFullImageIsAvailableShowItInHub() {
        let asyncImage = AsyncImageMock()
        let fullImage = UIImage()
        let mediaEditor = MediaEditor(asyncImage)
        UIApplication.shared.topWindow?.addSubview(mediaEditor.view)

        asyncImage.simulate(fullImageHasBeenDownloaded: fullImage)

        expect((mediaEditor.hub.collectionView(mediaEditor.hub.imagesCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as? MediaEditorImageCell)?.imageView.image).toEventually(equal(fullImage))
    }

    func testWhenFullImageIsAvailableHideActivityIndicatorView() {
        let asyncImage = AsyncImageMock()
        let fullImage = UIImage()
        let mediaEditor = MediaEditor(asyncImage)
        UIApplication.shared.topWindow?.addSubview(mediaEditor.view)

        asyncImage.simulate(fullImageHasBeenDownloaded: fullImage)

        expect(mediaEditor.hub.activityIndicatorView.isHidden).toEventually(beTrue())
    }

    func testPresentCapabilityAfterFullImageIsAvailable() {
        let asyncImage = AsyncImageMock()
        let fullImage = UIImage()
        let mediaEditor = MediaEditor(asyncImage)

        asyncImage.simulate(fullImageHasBeenDownloaded: fullImage)

        expect(mediaEditor.currentCapability).toEventuallyNot(beNil())
        expect(mediaEditor.visibleViewController).to(equal(mediaEditor.currentCapability?.viewController))
    }

    func testCallCancelOnAsyncImageWhenUserCancel() {
        let asyncImage = AsyncImageMock()
        let mediaEditor = MediaEditor(asyncImage)

        mediaEditor.hub.cancelButton.sendActions(for: .touchUpInside)

        expect(asyncImage.didCallCancel).to(beTrue())
    }

    func testDoNotDisplayThumbnailIfFullImageIsAlreadyVisible() {
        let asyncImage = AsyncImageMock()
        let fullImage = UIImage(color: .white)!
        let thumbImage = UIImage(color: .black)!
        let mediaEditor = MediaEditor(asyncImage)
        UIApplication.shared.topWindow?.addSubview(mediaEditor.view)

        asyncImage.simulate(fullImageHasBeenDownloaded: fullImage)
        asyncImage.simulate(thumbHasBeenDownloaded: thumbImage)

        expect((mediaEditor.hub.imagesCollectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? MediaEditorImageCell)?.imageView.image).toEventually(equal(fullImage))
        expect((mediaEditor.hub.imagesCollectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? MediaEditorImageCell)?.imageView.image).toEventuallyNot(equal(thumbImage))
    }

    func testHidesThumbsToolbar() {
        let asyncImage = AsyncImageMock()

        let mediaEditor = MediaEditor(asyncImage)

        expect(mediaEditor.hub.thumbsToolbar.isHidden).to(beTrue())
    }

    // WHEN: Multiple images + one single capability

    func testShowThumbs() {
        let whiteImage = UIImage(color: .white)!
        let blackImage = UIImage(color: .black)!

        let mediaEditor = MediaEditor([whiteImage, blackImage])

        let firstThumb = mediaEditor.hub.collectionView(mediaEditor.hub.thumbsCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as? MediaEditorThumbCell
        let secondThumb = mediaEditor.hub.collectionView(mediaEditor.hub.thumbsCollectionView, cellForItemAt: IndexPath(row: 1, section: 0)) as? MediaEditorThumbCell
        expect(firstThumb?.thumbImageView.image).to(equal(whiteImage))
        expect(secondThumb?.thumbImageView.image).to(equal(blackImage))
    }

    func testPresentsTheHub() {
        let whiteImage = UIImage(color: .white)!
        let blackImage = UIImage(color: .black)!

        let mediaEditor = MediaEditor([whiteImage, blackImage])

        expect(mediaEditor.currentCapability).to(beNil())
        expect(mediaEditor.visibleViewController).to(equal(mediaEditor.hub))
    }

    func testTappingACapabilityPresentsIt() {
        let whiteImage = UIImage(color: .white)!
        let blackImage = UIImage(color: .black)!
        let mediaEditor = MediaEditor([whiteImage, blackImage])

        mediaEditor.capabilityTapped(0)

        expect(mediaEditor.currentCapability).toNot(beNil())
        expect(mediaEditor.visibleViewController).to(equal(mediaEditor.currentCapability?.viewController))
    }

    func testCallingOnCancelWhenShowingACapabilityGoesBackToHub() {
        let whiteImage = UIImage(color: .white)!
        let blackImage = UIImage(color: .black)!
        let mediaEditor = MediaEditor([whiteImage, blackImage])
        mediaEditor.capabilityTapped(0)

        mediaEditor.currentCapability?.onCancel()

        expect(mediaEditor.currentCapability).to(beNil())
        expect(mediaEditor.visibleViewController).to(equal(mediaEditor.hub))
    }

    func testCallingOnFinishWhenShowingACapabilityUpdatesTheImage() {
        let whiteImage = UIImage(color: .white)!
        let blackImage = UIImage(color: .black)!
        let editedImage = UIImage()
        let mediaEditor = MediaEditor([whiteImage, blackImage])
        mediaEditor.capabilityTapped(0)

        mediaEditor.currentCapability?.onFinishEditing(editedImage, [.crop])

        expect(mediaEditor.images[0]).to(equal(editedImage))
        expect(mediaEditor.hub.availableImages[0]).to(equal(editedImage))
        expect(mediaEditor.hub.availableThumbs[0]).to(equal(editedImage))
    }

    // WHEN: Multiple async images + one single capability

    func testShowThumbsToolbar() {
        let asyncImages = [AsyncImageMock(), AsyncImageMock()]

        let mediaEditor = MediaEditor(asyncImages)

        expect(mediaEditor.hub.thumbsToolbar.isHidden).to(beFalse())
    }
}

class MockCapability: MediaEditorCapability {
    static var name = "MockCapability"

    static var icon = UIImage()

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

private class AsyncImageMock: AsyncImage {
    var didCallThumbnail = false
    var didCallFull = false
    var didCallCancel = false

    var finishedRetrievingThumbnail: ((UIImage?) -> ())?
    var finishedRetrievingFullImage: ((UIImage?) -> ())?

    var thumb: UIImage?

    func thumbnail(finishedRetrievingThumbnail: @escaping (UIImage?) -> ()) {
        didCallThumbnail = true
        self.finishedRetrievingThumbnail = finishedRetrievingThumbnail
    }

    func full(finishedRetrievingFullImage: @escaping (UIImage?) -> ()) {
        didCallFull = true
        self.finishedRetrievingFullImage = finishedRetrievingFullImage
    }

    func cancel() {
        didCallCancel = true
    }

    func simulate(thumbHasBeenDownloaded thumb: UIImage) {
        finishedRetrievingThumbnail?(thumb)
    }

    func simulate(fullImageHasBeenDownloaded image: UIImage) {
        finishedRetrievingFullImage?(image)
    }
}

private class UIViewControllerMock: UIViewController {
    var didCallPresentWith: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresentWith = viewControllerToPresent
    }
}
