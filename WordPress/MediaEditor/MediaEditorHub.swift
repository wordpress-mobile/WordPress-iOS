import UIKit

class MediaEditorHub: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cancelIconButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIVisualEffectView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!
    @IBOutlet weak var horizontalToolbar: UIView!
    @IBOutlet weak var verticalToolbar: UIView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var thumbsToolbar: UIView!
    @IBOutlet weak var thumbsCollectionView: UICollectionView!

    var onCancel: (() -> ())?

    var numberOfThumbs = 0 {
        didSet {
            reloadThumbsCollectionView()
        }
    }

    var availableThumbs: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        hideActivityIndicator()
        setupForOrientation()
        thumbsCollectionView.dataSource = self
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

    func show(thumb: UIImage, at index: Int) {
        guard let cell = thumbsCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorThumbCell else {
            return
        }

        cell.thumbImageView.image = thumb
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

        if let cancelIcon = styles[.cancelIcon] as? UIImage {
            cancelIconButton.setImage(cancelIcon, for: .normal)
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

    private func reloadThumbsCollectionView() {
        thumbsCollectionView.reloadData()
        thumbsToolbar.isHidden = numberOfThumbs > 1 ? false : true
    }

    private func setupForOrientation() {
        let isLandscape = UIDevice.current.orientation.isLandscape
        mainStackView.axis = isLandscape ? .horizontal : .vertical
        mainStackView.semanticContentAttribute = isLandscape ? .forceRightToLeft : .unspecified
        horizontalToolbar.isHidden = isLandscape
        verticalToolbar.isHidden = !isLandscape
    }

    static func initialize() -> MediaEditorHub {
        return UIStoryboard(name: "MediaEditorHub", bundle: nil).instantiateViewController(withIdentifier: "hubViewController") as! MediaEditorHub
    }

}

extension MediaEditorHub: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfThumbs
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "thumbCell", for: indexPath)
        let thumbCell = cell as? MediaEditorThumbCell

        thumbCell?.thumbImageView.image = availableThumbs.indices.contains(indexPath.row) ? availableThumbs[indexPath.row] : nil

        return cell
    }
}
