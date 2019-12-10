import UIKit

public class MediaEditor: UINavigationController {
    static var capabilities: [MediaEditorCapability.Type] = [MediaEditorCrop.self]

    var hub: MediaEditorHub

    var image: UIImage?

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
        hub = MediaEditorHub()
        super.init(rootViewController: hub)
        presentIfSingleImageAndCapability()
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
        navigationBar.isHidden = true
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

    private func present(capability capabilityEntity: MediaEditorCapability.Type) {
        guard let image = image else {
            return
        }

        let capability = capabilityEntity.init(
            image,
            onFinishEditing: { image, actions in
                self.onFinishEditing?(image, actions)
            }, onCancel: {
                self.dismiss(animated: true)
            }
        )
        capability.apply(styles: styles)
        currentCapability = capability
        pushViewController(capability.viewController, animated: false)
    }
}
