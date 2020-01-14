import UIKit

/**
 Since each capability has it's own (or is a) View Controller, the Media Editor
 is a Navigation Controller that presents them.
 Also, by also being a ViewController, this allows it to be custom presented.
 */
public class MediaEditor: UINavigationController {
    static var capabilities: [MediaEditorCapability.Type] = [MediaEditorCropZoomRotate.self]

    var hub: MediaEditorHub = {
        let hub: MediaEditorHub = MediaEditorHub.initialize()
        hub.loadViewIfNeeded()
        return hub
    }()

    var images: [Int: UIImage] = [:]

    var asyncImages: [AsyncImage] = []

    var editedImagesIndexes: Set<Int> = []

    var onFinishEditing: (([AsyncImage], [MediaEditorOperation]) -> ())?

    var onCancel: (() -> ())?

    var actions: [MediaEditorOperation] = []

    var isSingleImageAndCapability: Bool {
        return ((asyncImages.count == 1) || (images.count == 1 && asyncImages.count == 0)) && Self.capabilities.count == 1
    }

    private(set) var currentCapability: MediaEditorCapability?

    private var isEditingPlainUIImages = false

    var selectedImageIndex: Int {
        return hub.selectedThumbIndex
    }

    public var styles: MediaEditorStyles = [:] {
        didSet {
            currentCapability?.apply(styles: styles)
            hub.apply(styles: styles)
        }
    }

    init(_ image: UIImage) {
        self.images = [0: image]
        super.init(rootViewController: hub)
        setup()
    }

    init(_ images: [UIImage]) {
        self.images = images.enumerated().reduce(into: [:]) { $0[$1.offset] = $1.element }
        super.init(rootViewController: hub)
        setup()
    }

    init(_ asyncImage: AsyncImage) {
        self.asyncImages.append(asyncImage)
        super.init(rootViewController: hub)
        setup()
    }

    init(_ asyncImages: [AsyncImage]) {
        self.asyncImages = asyncImages
        super.init(rootViewController: hub)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        isEditingPlainUIImages = images.count > 0

        hub.delegate = self

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
        navigationBar.isHidden = true
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentCapability = nil
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping ([AsyncImage], [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        viewController?.present(self, animated: true)
    }

    private func setup() {
        setupHub()
        setupForAsync()
        presentIfSingleImageAndCapability()
    }

    private func setupHub() {
        hub.onCancel = { [weak self] in
            self?.cancel()
        }

        hub.onDone = { [weak self] in
            self?.done()
        }

        hub.apply(styles: styles)

        hub.availableThumbs = images

        hub.numberOfThumbs = max(images.count, asyncImages.count)

        hub.capabilities = Self.capabilities.reduce(into: []) { $0.append(($1.name, $1.icon)) }

        hub.apply(styles: styles)
    }

    private func setupForAsync() {
        asyncImages.enumerated().forEach { offset, asyncImage in
            if let thumb = asyncImage.thumb {
                thumbnailAvailable(thumb, offset: offset)
            } else {
                asyncImage.thumbnail(finishedRetrievingThumbnail: { [weak self] thumb in
                    self?.thumbnailAvailable(thumb, offset: offset)
                })
            }
        }

        if isSingleImageAndCapability {
            hub.disableDoneButton()
            capabilityTapped(0)
        }
    }

    func presentIfSingleImageAndCapability() {
        guard isSingleImageAndCapability, let image = images[0], let capabilityEntity = Self.capabilities.first else {
            return
        }

        present(capability: capabilityEntity, with: image)
    }

    private func cancel() {
        if currentCapability == nil {
            cancelPendingAsyncImagesAndDismiss()
        } else if isSingleImageAndCapability {
            cancelPendingAsyncImagesAndDismiss()
        } else {
            dismissCapability()
        }
    }

    private func done() {
        let outputImages = isEditingPlainUIImages ? mapEditedImages() : mapEditedAsyncImages()
        onFinishEditing?(outputImages, actions)
        dismiss(animated: true)
    }

    /*
     Map the images hash to an images array preserving the original order,
     since Hashes are non-order preserving.
     */
    private func mapEditedImages() -> [UIImage] {
        return images.enumerated().compactMap { index, _ in images[index] }
    }

    private func mapEditedAsyncImages() -> [AsyncImage] {
        var editedImages: [AsyncImage] = []

        for (index, var asyncImage) in asyncImages.enumerated() {
            if editedImagesIndexes.contains(index), let editedImage = images[index] {
                asyncImage.isEdited = true
                asyncImage.editedImage = editedImage
            }
            editedImages.append(asyncImage)
        }

        return editedImages
    }

    private func cancelPendingAsyncImagesAndDismiss() {
        onCancel?()
        asyncImages.forEach { $0.cancel() }
        dismiss(animated: true)
    }

    private func present(capability capabilityEntity: MediaEditorCapability.Type, with image: UIImage) {
        prepareTransition()

        let capability = capabilityEntity.init(
            image,
            onFinishEditing: { [weak self] image, actions in
                self?.finishEditing(image: image, actions: actions)
            },
            onCancel: { [weak self] in
                self?.cancel()
        }
        )
        capability.apply(styles: styles)
        currentCapability = capability

        pushViewController(capability.viewController, animated: false)
    }

    private func finishEditing(image: UIImage, actions: [MediaEditorOperation]) {
        images[selectedImageIndex] = image

        self.actions.append(contentsOf: actions)

        if !actions.isEmpty {
            editedImagesIndexes.insert(selectedImageIndex)
        }

        if isSingleImageAndCapability {
            done()
            dismiss(animated: true)
        } else {
            hub.show(image: image, at: selectedImageIndex)
            dismissCapability()
        }
    }

    private func dismissCapability() {
        prepareTransition()
        popViewController(animated: false)
        currentCapability = nil
    }

    private func prepareTransition() {
        let transition: CATransition = CATransition()
        transition.duration = Constants.transitionDuration
        transition.type = .fade
        view.layer.add(transition, forKey: nil)
    }

    private func thumbnailAvailable(_ thumb: UIImage?, offset: Int) {
        guard let thumb = thumb else {
            return
        }

        DispatchQueue.main.async {
            self.hub.show(thumb: thumb, at: offset)
        }
    }

    private func fullImageAvailable(_ image: UIImage?, offset: Int) {
        guard let image = image else {
            DispatchQueue.main.async {
                self.hub.failedToLoad(at: offset)
            }
            return
        }

        self.images[offset] = image

        DispatchQueue.main.async {
            self.hub.hideActivityIndicator()

            self.hub.enableDoneButton()

            self.presentIfSingleImageAndCapability()

            self.hub.show(image: image, at: offset)
        }
    }

    private enum Constants {
        static let transitionDuration = 0.3
    }
}

extension MediaEditor: MediaEditorHubDelegate {
    func capabilityTapped(_ index: Int) {
        if let image = images[selectedImageIndex] {
            present(capability: Self.capabilities[index], with: image)
        } else {
            let offset = selectedImageIndex
            hub.loadingImage(at: offset)
            asyncImages[selectedImageIndex].full(finishedRetrievingFullImage: { [weak self] image in
                DispatchQueue.main.async {

                    self?.hub.loadedImage(at: offset)

                    self?.fullImageAvailable(image, offset: offset)

                    if self?.selectedImageIndex == offset, let image = image {
                        self?.present(capability: Self.capabilities[index], with: image)
                    }

                }
            })
        }
    }
}
