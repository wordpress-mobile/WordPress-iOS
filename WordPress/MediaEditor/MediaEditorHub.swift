import UIKit

class MediaEditorHub: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIVisualEffectView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!

    var onCancel: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        hideActivityIndicator()
    }

    @IBAction func cancel(_ sender: Any) {
        onCancel?()
    }

    func show(image: UIImage) {
        imageView.image = image
    }

    func apply(styles: MediaEditorStyles) {
        loadViewIfNeeded()

        if let cancelLabel = styles[.cancelLabel] as? String {
            cancelButton.setTitle(cancelLabel, for: .normal)
        }

        if let cancelColor = styles[.cancelColor] as? UIColor {
            cancelButton.tintColor = cancelColor
        }

        if let loadingLabel = styles[.loadingLabel] as? String {
            activityIndicatorLabel.text = loadingLabel
        }
    }

    func showActivityIndicator() {
        activityIndicatorView.isHidden = false
    }

    func hideActivityIndicator() {
        activityIndicatorView.isHidden = true
    }

    static func initialize() -> MediaEditorHub {
        return UIStoryboard(name: "MediaEditorHub", bundle: nil).instantiateViewController(withIdentifier: "hubViewController") as! MediaEditorHub
    }

}
