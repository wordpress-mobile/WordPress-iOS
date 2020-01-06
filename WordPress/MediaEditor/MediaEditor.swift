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

    var images: [UIImage] = []

    var asyncImages: [AsyncImage] = []

    var onFinishEditing: ((UIImage, [MediaEditorOperation]) -> ())?

    var onCancel: (() -> ())?

    var actions: [MediaEditorOperation] = []

    var isSingleImageAndCapability: Bool {
        return (asyncImages.count == 1 || images.count == 1) && Self.capabilities.count == 1
    }

    private(set) var currentCapability: MediaEditorCapability?

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
        self.images.append(image)
        super.init(rootViewController: hub)
        setup()
    }

    init(_ images: [UIImage]) {
        self.images = images
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

        hub.delegate = self

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
        navigationBar.isHidden = true
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentCapability = nil
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        viewController?.present(self, animated: true)
    }

    private func setup() {
        hub.onCancel = { [weak self] in
            self?.cancel()
        }

        hub.apply(styles: styles)

        hub.availableThumbs = images.enumerated().reduce(into: [:]) { $0[$1.offset] = $1.element }

        hub.numberOfThumbs = max(images.count, asyncImages.count)

        hub.capabilities = Self.capabilities.reduce(into: []) { $0.append(($1.name, $1.icon)) }

        setupForAsync()

        presentIfSingleImageAndCapability()
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
            showActivityIndicator()
            asyncImages.first?.full(finishedRetrievingFullImage: { [weak self] image in
                let offset = self?.selectedImageIndex ?? 0
                self?.fullImageAvailable(image, offset: offset)
            })
        }
    }

    func presentIfSingleImageAndCapability() {
        guard isSingleImageAndCapability, let image = images.first, let capabilityEntity = Self.capabilities.first else {
            return
        }

        present(capability: capabilityEntity, with: image)
    }

    private func cancel() {
        asyncImages.forEach { $0.cancel() }
        dismiss(animated: true)
    }

    private func present(capability capabilityEntity: MediaEditorCapability.Type, with image: UIImage) {
        prepareTransition()

        let capability = capabilityEntity.init(
            image,
            onFinishEditing: { [weak self] image, actions in
                self?.actions.append(contentsOf: actions)
                self?.onFinishEditing?(image, actions)
                self?.dismiss(animated: true)
            },
            onCancel: { [weak self] in
                self?.cancel()
        }
        )
        capability.apply(styles: styles)
        currentCapability = capability

        pushViewController(capability.viewController, animated: false)
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
            return
        }

        self.images.append(image)

        DispatchQueue.main.async {
            self.hideActivityIndicator()

            self.presentIfSingleImageAndCapability()

            self.hub.show(image: image, at: offset)
        }
    }

    private func showActivityIndicator() {
        hub.showActivityIndicator()
    }

    private func hideActivityIndicator() {
        hub.hideActivityIndicator()
    }

    private enum Constants {
        static let transitionDuration = 0.3
    }
}

extension MediaEditor: MediaEditorHubDelegate {
    func capabilityTapped(_ index: Int) {

    }
}
