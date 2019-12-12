import UIKit

class MediaEditorHub: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cancelIconButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIVisualEffectView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!
    @IBOutlet weak var horizontalToolbar: UIView!
    @IBOutlet weak var verticalToolbar: UIView!

    @IBOutlet weak var toolbarTrailingPortrait: NSLayoutConstraint!
    @IBOutlet weak var toolbarHeightPortrait: NSLayoutConstraint!
    @IBOutlet weak var imageBottomPortrait: NSLayoutConstraint!
    @IBOutlet weak var imageLeadingPortrait: NSLayoutConstraint!

    @IBOutlet weak var toolbarTopLandscape: NSLayoutConstraint!
    @IBOutlet weak var toolbarWidthLandscape: NSLayoutConstraint!
    @IBOutlet weak var imageBottomLandscape: NSLayoutConstraint!
    @IBOutlet weak var imageLeadingLandscape: NSLayoutConstraint!

    var portraitConstraints: [NSLayoutConstraint] {
        return [toolbarTrailingPortrait, toolbarHeightPortrait, imageBottomPortrait, imageLeadingPortrait]
    }

    var landscapeConstraints: [NSLayoutConstraint] {
        return [toolbarTopLandscape, toolbarWidthLandscape, imageBottomLandscape, imageLeadingLandscape]
    }

    var onCancel: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        hideActivityIndicator()
        setupForOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupForOrientation()
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
            cancelIconButton.tintColor = cancelColor
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

    private func setupForOrientation() {
        let isLandscape = UIDevice.current.orientation.isLandscape
        portraitConstraints.forEach { $0.isActive = !isLandscape }
        landscapeConstraints.forEach { $0.isActive = isLandscape }
        horizontalToolbar.isHidden = isLandscape
        verticalToolbar.isHidden = !isLandscape
    }

    static func initialize() -> MediaEditorHub {
        return UIStoryboard(name: "MediaEditorHub", bundle: nil).instantiateViewController(withIdentifier: "hubViewController") as! MediaEditorHub
    }

}
