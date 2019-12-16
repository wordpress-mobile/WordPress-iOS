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

    var image: UIImage?

    var asyncImage: AsyncImage?

    var onFinishEditing: ((UIImage, [MediaEditorOperation]) -> ())?

    var onCancel: (() -> ())?

    private(set) var currentCapability: MediaEditorCapability?

    public var styles: MediaEditorStyles = [:] {
        didSet {
            currentCapability?.apply(styles: styles)
            hub.apply(styles: styles)
        }
    }

    init(_ image: UIImage) {
        self.image = image
        super.init(rootViewController: hub)
        setup()
    }

    init(_ asyncImage: AsyncImage) {
        self.asyncImage = asyncImage
        super.init(rootViewController: hub)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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

        showActivityIndicator()
        asyncImage?.full(finishedRetrievingFullImage: fullImageAvailable)
    }

    func presentIfSingleImageAndCapability() {
        guard let image = image, Self.capabilities.count == 1, let capabilityEntity = Self.capabilities.first else {
            return
        }

        present(capability: capabilityEntity, with: image)
    }

    private func cancel() {
        asyncImage?.cancel()
        dismiss(animated: true)
    }

    private func present(capability capabilityEntity: MediaEditorCapability.Type, with image: UIImage) {
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
            self.hideActivityIndicator()

            self.presentIfSingleImageAndCapability()

            self.hub.show(image: image)
        }
    }

    private func showActivityIndicator() {
        hub.showActivityIndicator()
    }

    private func hideActivityIndicator() {
        hub.hideActivityIndicator()
    }
}
