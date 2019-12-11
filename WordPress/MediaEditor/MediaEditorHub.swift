import UIKit

class MediaEditorHub: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!

    var onCancel: (() -> ())?

    @IBAction func cancel(_ sender: Any) {
        onCancel?()
    }

    func show(image: UIImage) {
        imageView.image = image
    }

    static func initialize() -> MediaEditorHub {
        return UIStoryboard(name: "MediaEditorHub", bundle: nil).instantiateViewController(withIdentifier: "hubViewController") as! MediaEditorHub
    }

    func apply(styles: MediaEditorStyles) {
        loadViewIfNeeded()

        if let cancelLabel = styles[.cancelLabel] as? String {
            cancelButton.setTitle(cancelLabel, for: .normal)
        }

        if let cancelColor = styles[.cancelColor] as? UIColor {
            cancelButton.tintColor = cancelColor
        }
    }

}
