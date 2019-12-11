import UIKit

public class MediaEditor: UINavigationController {
    static var capabilities: [MediaEditorCapability.Type] = [MediaEditorCrop.self]

    var hub: MediaEditorHub

    var image: UIImage?

    var asyncImage: AsyncImage?

    var onFinishEditing: ((UIImage, [MediaEditorOperation]) -> ())?

    var onCancel: (() -> ())?

    private(set) var currentCapability: MediaEditorCapability?

    public var styles: MediaEditorStyles = [:] {
        didSet {
            currentCapability?.apply(styles: styles)
        }
    }

    init(_ image: UIImage) {
        self.image = image
        hub = MediaEditorHub.initialize()
        super.init(rootViewController: hub)
        setup()
    }

    init(_ asyncImage: AsyncImage, mediaEditorHub: MediaEditorHub = MediaEditorHub.initialize()) {
        self.asyncImage = asyncImage
        self.hub = mediaEditorHub
        super.init(rootViewController: hub)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
        navigationBar.isHidden = true
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        viewController?.present(self, animated: true)
    }

    private func setup() {
        hub.onCancel = cancel

        setupForAsync()

        presentIfSingleImageAndCapability()
    }

    private func setupForAsync() {
        if let thumb = asyncImage?.thumb {
            hub.show(image: thumb)
        } else {
            asyncImage?.thumbnail(finishedRetrievingThumbnail: thumbnailAvailable)
        }

        asyncImage?.full(finishedRetrievingFullImage: fullImageAvailable)
    }

    private func presentIfSingleImageAndCapability() {
        guard let _ = image, Self.capabilities.count == 1, let capabilityEntity = Self.capabilities.first else {
            return
        }

        present(capability: capabilityEntity)
    }

    private func cancel() {
        dismiss(animated: true)
    }

    private func present(capability capabilityEntity: MediaEditorCapability.Type) {
        guard let image = image else {
            return
        }

        prepareTransition()

        let capability = capabilityEntity.init(
            image,
            onFinishEditing: { image, actions in
                self.onFinishEditing?(image, actions)
            },
            onCancel: cancel
        )
        capability.apply(styles: styles)
        currentCapability = capability

        pushViewController(capability.viewController, animated: false)
    }

    private func prepareTransition() {
        let transition: CATransition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.fade
        view.layer.add(transition, forKey: nil)
    }

    private func thumbnailAvailable(_ thumb: UIImage?) {
        guard let thumb = thumb else {
            return
        }

        DispatchQueue.main.async {
            self.hub.show(image: thumb)
        }
    }

    private func fullImageAvailable(_ image: UIImage?) {
        guard let image = image else {
            return
        }

        self.image = image

        DispatchQueue.main.async {
            self.presentIfSingleImageAndCapability()

            self.hub.show(image: image)
        }
    }
}
