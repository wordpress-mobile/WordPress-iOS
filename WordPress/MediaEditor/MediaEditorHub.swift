import UIKit

class MediaEditorHub: UIViewController {

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var doneIconButton: UIButton!
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
    @IBOutlet weak var capabilitiesCollectionView: UICollectionView!

    weak var delegate: MediaEditorHubDelegate?

    var onCancel: (() -> ())?

    var onDone: (() -> ())?

    var numberOfThumbs = 0 {
        didSet {
            reloadImagesAndReposition()
        }
    }

    var capabilities: [(String, UIImage)] = [] {
        didSet {
            setupCapabilities()
        }
    }

    var availableThumbs: [Int: UIImage] = [:]

    var availableImages: [Int: UIImage] = [:]

    private(set) var selectedThumbIndex = 0 {
        didSet {
            highlightSelectedThumb(current: selectedThumbIndex, before: oldValue)
            showOrHideActivityIndicatorAndCapabilities()
        }
    }

    private(set) var isUserScrolling = false

    private var selectedColor: UIColor?

    private var indexesOfImagesBeingLoaded: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupForOrientation()
        thumbsCollectionView.dataSource = self
        thumbsCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.delegate = self
        capabilitiesCollectionView.dataSource = self
        capabilitiesCollectionView.delegate = self
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupForOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupForOrientation()

        coordinator.animate(alongsideTransition: { _ in
            self.reloadImagesAndReposition()
        })
    }

    @IBAction func cancel(_ sender: Any) {
        onCancel?()
    }

    @IBAction func done(_ sender: Any) {
        onDone?()
    }

    func show(image: UIImage, at index: Int) {
        availableImages[index] = image
        availableThumbs[index] = image

        let imageCell = imagesCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorImageCell
        imageCell?.imageView.image = image

        let cell = thumbsCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorThumbCell
        cell?.thumbImageView.image = image

        showOrHideActivityIndicatorAndCapabilities()
    }

    func show(thumb: UIImage, at index: Int) {
        availableThumbs[index] = thumb

        let cell = thumbsCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorThumbCell
        cell?.thumbImageView.image = thumb

        let imageCell = imagesCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? MediaEditorImageCell
        imageCell?.imageView.image = availableImages[index] ?? thumb

        showOrHideActivityIndicatorAndCapabilities()
    }

    func apply(styles: MediaEditorStyles) {
        loadViewIfNeeded()

        if let cancelLabel = styles[.cancelLabel] as? String {
            cancelButton.setTitle(cancelLabel, for: .normal)
        }

        if let doneLabel = styles[.doneLabel] as? String {
            doneButton.setTitle(doneLabel, for: .normal)
        }

        if let cancelColor = styles[.cancelColor] as? UIColor {
            cancelButton.tintColor = cancelColor
            cancelIconButton.tintColor = cancelColor
        }

        if let doneColor = styles[.doneColor] as? UIColor {
            doneButton.tintColor = doneColor
            doneIconButton.tintColor = doneColor
        }

        if let cancelIcon = styles[.cancelIcon] as? UIImage {
            cancelIconButton.setImage(cancelIcon, for: .normal)
        }

        if let doneIcon = styles[.doneIcon] as? UIImage {
            doneIconButton.setImage(doneIcon, for: .normal)
        }

        if let loadingLabel = styles[.loadingLabel] as? String {
            activityIndicatorLabel.text = loadingLabel
        }

        if let color = styles[.selectedColor] as? UIColor {
            selectedColor = color
        }
    }

    func showActivityIndicator() {
        activityIndicatorView.isHidden = false
    }

    func hideActivityIndicator() {
        activityIndicatorView.isHidden = true
    }

    func disableDoneButton() {
        doneButton.isEnabled = false
        doneIconButton.isEnabled = false
    }

    func enableDoneButton() {
        doneButton.isEnabled = true
        doneIconButton.isEnabled = true
    }

    func loadingImage(at index: Int) {
        indexesOfImagesBeingLoaded.append(index)
        showOrHideActivityIndicatorAndCapabilities()
    }

    func loadedImage(at index: Int) {
        indexesOfImagesBeingLoaded = indexesOfImagesBeingLoaded.filter { $0 != index }
        showOrHideActivityIndicatorAndCapabilities()
    }

    private func reloadImagesAndReposition() {
        thumbsCollectionView.reloadData()
        imagesCollectionView.reloadData()
        thumbsCollectionView.layoutIfNeeded()
        thumbsCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
        imagesCollectionView.scrollToItem(at: IndexPath(row: self.selectedThumbIndex, section: 0), at: .right, animated: false)
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
        if let layout = capabilitiesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
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

    private func showOrHideActivityIndicatorAndCapabilities() {
        let imageAvailable = availableThumbs[selectedThumbIndex] ?? availableImages[selectedThumbIndex]

        let isBeingLoaded = imageAvailable == nil || indexesOfImagesBeingLoaded.contains(selectedThumbIndex)

        if isBeingLoaded {
            showActivityIndicator()
            disableCapabilities()
        } else {
            hideActivityIndicator()
            enableCapabilities()
        }
    }

    private func disableCapabilities() {
        capabilitiesCollectionView.isUserInteractionEnabled = false
        capabilitiesCollectionView.layer.opacity = 0.5
    }

    private func enableCapabilities() {
        capabilitiesCollectionView.isUserInteractionEnabled = true
        capabilitiesCollectionView.layer.opacity = 1
    }

    private func setupCapabilities() {
        capabilitiesCollectionView.isHidden = capabilities.count > 1 || numberOfThumbs > 1 ? false : true
        capabilitiesCollectionView.reloadData()
    }

    static func initialize() -> MediaEditorHub {
        return UIStoryboard(name: "MediaEditorHub", bundle: nil).instantiateViewController(withIdentifier: "hubViewController") as! MediaEditorHub
    }

    private enum Constants {
        static var thumbCellIdentifier = "thumbCell"
        static var imageCellIdentifier = "imageCell"
        static var capabCellIdentifier = "capabilityCell"
    }
}

// MARK: - UICollectionViewDataSource

extension MediaEditorHub: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == capabilitiesCollectionView ? capabilities.count : numberOfThumbs
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == thumbsCollectionView {
            return cellForThumbsCollectionView(cellForItemAt: indexPath)
        } else if collectionView == imagesCollectionView {
            return cellForImagesCollectionView(cellForItemAt: indexPath)
        }

        return cellForCapabilityCollectionView(cellForItemAt: indexPath)
    }

    private func cellForThumbsCollectionView(cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = thumbsCollectionView.dequeueReusableCell(withReuseIdentifier: Constants.thumbCellIdentifier, for: indexPath)

        if let thumbCell = cell as? MediaEditorThumbCell {
            thumbCell.thumbImageView.image = availableThumbs[indexPath.row]
            indexPath.row == selectedThumbIndex ? thumbCell.showBorder(color: selectedColor) : thumbCell.hideBorder()
        }

        return cell
    }

    private func cellForImagesCollectionView(cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imagesCollectionView.dequeueReusableCell(withReuseIdentifier: Constants.imageCellIdentifier, for: indexPath)

        if let imageCell = cell as? MediaEditorImageCell {
            imageCell.imageView.image = availableImages[indexPath.row] ?? availableThumbs[indexPath.row]
        }

        showOrHideActivityIndicatorAndCapabilities()

        return cell
    }

    private func cellForCapabilityCollectionView(cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = capabilitiesCollectionView.dequeueReusableCell(withReuseIdentifier: Constants.capabCellIdentifier, for: indexPath)

        if let capabilityCell = cell as? MediaEditorCapabilityCell {
            capabilityCell.configure(capabilities[indexPath.row])
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaEditorHub: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == imagesCollectionView {
            return CGSize(width: imagesCollectionView.frame.width, height: imagesCollectionView.frame.height)
        }

        return CGSize(width: 44, height: 44)
    }
}

// MARK: - UICollectionViewDelegate

extension MediaEditorHub: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == thumbsCollectionView {
            selectedThumbIndex = indexPath.row
            imagesCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
        } else if collectionView == capabilitiesCollectionView {
            delegate?.capabilityTapped(indexPath.row)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == imagesCollectionView, isUserScrolling else {
            return
        }

        let imageIndexBasedOnScroll = Int(round(scrollView.bounds.origin.x / imagesCollectionView.frame.width))

        thumbsCollectionView.selectItem(at: IndexPath(row: imageIndexBasedOnScroll, section: 0), animated: true, scrollPosition: .right)
        selectedThumbIndex = imageIndexBasedOnScroll
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == imagesCollectionView else {
            return
        }

        isUserScrolling = true
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == imagesCollectionView else {
            return
        }

        isUserScrolling = false
    }
}

protocol MediaEditorHubDelegate: class {
    func capabilityTapped(_ index: Int)
}
