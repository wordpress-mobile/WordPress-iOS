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
        presentIfSingleImageAndCapability()
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
        navigationBar.isHidden = true
    }

    init(_ asyncImage: AsyncImage, mediaEditorHub: MediaEditorHub = MediaEditorHub.initialize()) {
        self.asyncImage = asyncImage
        self.hub = mediaEditorHub
        super.init(rootViewController: hub)
        hub.onCancel = self.cancel
        presentIfSingleImageAndCapability()
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
        navigationBar.isHidden = true

        if let thumb = asyncImage.thumb {
            hub.show(image: thumb)
        }
        asyncImage.thumbnail(finishedRetrievingThumbnail: finishedRetrievingThumbnail)
        asyncImage.full(finishedRetrievingFullImage: finishedRetrievingFullImage)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        viewController?.present(self, animated: true)
    }

    func presentIfSingleImageAndCapability() {
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

        let transition: CATransition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.fade
        self.view.layer.add(transition, forKey: nil)

        let capability = capabilityEntity.init(
            image,
            onFinishEditing: { image, actions in
                self.onFinishEditing?(image, actions)
            },
            onCancel: self.cancel
        )
        capability.apply(styles: styles)
        currentCapability = capability
        pushViewController(capability.viewController, animated: false)
    }

    private func finishedRetrievingThumbnail(_ image: UIImage?) {
        guard let image = image else {
            return
        }

        DispatchQueue.main.async {
            self.hub.show(image: image)
        }
    }

    private func finishedRetrievingFullImage(_ image: UIImage?) {
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
