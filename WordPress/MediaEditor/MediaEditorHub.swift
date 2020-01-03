import UIKit

class MediaEditorHub: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cancelIconButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIVisualEffectView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!
    @IBOutlet weak var horizontalToolbar: UIView!
    @IBOutlet weak var verticalToolbar: UIView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var thumbsToolbar: UIView!
    @IBOutlet weak var thumbsCollectionView: UICollectionView!
    @IBOutlet weak var imagesCollectionView: UICollectionView!

    var onCancel: (() -> ())?

    var numberOfThumbs = 0 {
        didSet {
            reloadThumbsCollectionView()
        }
    }

    var availableThumbs: [Int: UIImage] = [:]

    var availableImages: [Int: UIImage] = [:]

    private(set) var selectedThumbIndex = 0 {
        didSet {
            highlightSelectedThumb(current: selectedThumbIndex, before: oldValue)
        }
    }

    private(set) var isUserScrolling = false

    override func viewDidLoad() {
        super.viewDidLoad()
        hideActivityIndicator()
        setupForOrientation()
        thumbsCollectionView.dataSource = self
        thumbsCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.delegate = self
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupForOrientation()
    }

    @IBAction func cancel(_ sender: Any) {
        onCancel?()
    }

    func show(image: UIImage, at index: Int) {
        availableImages[index] = image

        let imageCell = imagesCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorImageCell
        imageCell?.imageView.image = image
    }

    func show(thumb: UIImage, at index: Int) {
        availableThumbs[index] = thumb

        let cell = thumbsCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorThumbCell
        cell?.thumbImageView.image = thumb

        let imageCell = imagesCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorImageCell
        imageCell?.imageView.image = availableImages[index] ?? thumb
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
        imagesCollectionView.reloadData()
        thumbsCollectionView.layoutIfNeeded()
        thumbsCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
        thumbsToolbar.isHidden = numberOfThumbs > 1 ? false : true
    }

    private func setupForOrientation() {
        let isLandscape = UIDevice.current.orientation.isLandscape
        mainStackView.axis = isLandscape ? .horizontal : .vertical
        mainStackView.semanticContentAttribute = isLandscape ? .forceRightToLeft : .unspecified
        horizontalToolbar.isHidden = isLandscape
        verticalToolbar.isHidden = !isLandscape
        if let layout = thumbsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = isLandscape ? .vertical : .horizontal
        }
        mainStackView.layoutIfNeeded()
        imagesCollectionView.scrollToItem(at: IndexPath(row: selectedThumbIndex, section: 0), at: .right, animated: false)
    }

    private func highlightSelectedThumb(current: Int, before: Int) {
        let current = thumbsCollectionView.cellForItem(at: IndexPath(row: current, section: 0)) as? MediaEditorThumbCell
        let before = thumbsCollectionView.cellForItem(at: IndexPath(row: before, section: 0)) as? MediaEditorThumbCell
        before?.hideBorder()
        current?.showBorder()
    }

    static func initialize() -> MediaEditorHub {
        return UIStoryboard(name: "MediaEditorHub", bundle: nil).instantiateViewController(withIdentifier: "hubViewController") as! MediaEditorHub
    }

}

// MARK: - UICollectionViewDataSource

extension MediaEditorHub: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfThumbs
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == thumbsCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "thumbCell", for: indexPath) as? MediaEditorThumbCell else {
                return UICollectionViewCell()
            }

            cell.thumbImageView.image = availableThumbs[indexPath.row]
            indexPath.row == selectedThumbIndex ? cell.showBorder() : cell.hideBorder()

            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? MediaEditorImageCell else {
            return UICollectionViewCell()
        }

        cell.imageView.image = availableImages[indexPath.row] ?? availableThumbs[indexPath.row]

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaEditorHub: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: imagesCollectionView.frame.width, height: imagesCollectionView.frame.height)
    }
}

// MARK: - UICollectionViewDelegate

extension MediaEditorHub: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == thumbsCollectionView else {
            return
        }

        selectedThumbIndex = indexPath.row
        imagesCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == imagesCollectionView, isUserScrolling else {
            return
        }

        let index = Int(round(scrollView.bounds.origin.x / imagesCollectionView.frame.width))

        thumbsCollectionView.selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .right)
        selectedThumbIndex = index
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isUserScrolling = false
    }
}
