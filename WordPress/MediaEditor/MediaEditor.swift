import UIKit

public class MediaEditor: UINavigationController {
    var hub: MediaEditorCrop

    init(_ image: UIImage) {
        hub = MediaEditorCrop(image: image)
        super.init(rootViewController: UIViewController())
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
        navigationBar.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        viewController?.present(self, animated: true)
        hub.edit(from: self, onFinishEditing: onFinishEditing, onCancel: onCancel)
    }
}
