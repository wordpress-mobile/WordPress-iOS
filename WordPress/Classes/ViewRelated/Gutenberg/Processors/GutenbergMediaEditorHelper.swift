import UIKit
import MediaEditor

class GutenbergMediaEditorHelper {

    let phImageManager: PHImageManager
    let mediaEditor: MediaEditor

    init(phImageManager: PHImageManager = PHImageManager.default(), mediaEditor: MediaEditor = MediaEditor()) {
        self.phImageManager = phImageManager
        self.mediaEditor = mediaEditor
    }

    func edit(asset: PHAsset, from viewController: UIViewController?, onFinishEditing: @escaping (UIImage?) -> ()) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        phImageManager.requestImage(for: asset,
                                    targetSize: asset.pixelSize(),
                                    contentMode: .default, options: options) { (image, info) in

            guard let image = image else {
                onFinishEditing(nil)
                return
            }

            self.mediaEditor.edit(image, from: viewController) { image in
                guard let image = image else {
                    onFinishEditing(nil)
                    viewController?.dismiss(animated: true)
                    return
                }

                onFinishEditing(image)
            }

        }
    }
}
