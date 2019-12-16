import UIKit

/**
 Since each capability has it's own (or is a) View Controller, the Media Editor
 is a Navigation Controller that presents them.
 Also, by also being a ViewController, this allows it to be custom presented.
 */
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
        hub = MediaEditorHub()
        super.init(coder: aDecoder)
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        viewController?.present(self, animated: true)
    }

    func presentIfSingleImageAndCapability() {
        guard let image = image, Self.capabilities.count == 1, let capabilityEntity = Self.capabilities.first else {
            return
        }

        present(capability: capabilityEntity, with: image)
    }

    private func present(capability capabilityEntity: MediaEditorCapability.Type, with image: UIImage) {
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
