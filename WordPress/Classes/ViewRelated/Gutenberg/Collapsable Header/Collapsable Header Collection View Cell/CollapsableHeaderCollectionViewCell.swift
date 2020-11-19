import UIKit
import Gutenberg
import Gridicons

class CollapsableHeaderCollectionViewCell: UICollectionViewCell {

    static let cellReuseIdentifier = "\(CollapsableHeaderCollectionViewCell.self)"
    static let nib = UINib(nibName: "\(CollapsableHeaderCollectionViewCell.self)", bundle: Bundle.main)
    static let selectionAnimationSpeed: Double = 0.25
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var checkmarkBackground: UIView!
    @IBOutlet weak var checkmarkImageView: UIImageView! {
        didSet {
            if #available(iOS 13.0, *) {
                checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
            } else {
                checkmarkImageView.image = UIImage.gridicon(.checkmarkCircle)
            }

            checkmarkImageView.tintColor = accentColor
        }
    }

    /// The throttle the requests to the imageURL polling if needed.
    private let throttle = Scheduler(seconds: 1)

    var previewURL: String? = nil {
        didSet {
            setImage(previewURL)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelImageDownload()
        previewURL = nil
        stopGhostAnimation()
    }

    var accentColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.muriel(color: .accent, .shade40)
                } else {
                    return UIColor.muriel(color: .accent, .shade50)
                }
            }
        } else {
            return UIColor.muriel(color: .accent, .shade50)
        }
    }

    var borderColor: UIColor {
        return UIColor.black.withAlphaComponent(0.08)
    }

    var borderWith: CGFloat = 0.5

    override var isSelected: Bool {
        didSet {
            checkmarkHidden(!isSelected, animated: true)
            styleSelectedBorder(animated: true)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleSelectedBorder()

        if #available(iOS 13.0, *) {
             styleShadow()
         } else {
             addShadow()
         }

        checkmarkImageView.isGhostableDisabled = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleSelectedBorder()
                styleShadow()
            }
        }
    }

    @available(iOS 13.0, *)
    func styleShadow() {
        if traitCollection.userInterfaceStyle == .dark {
            removeShadow()
        } else {
            addShadow()
        }
    }

    func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 5.0
        layer.shadowOpacity = 0.16
        layer.shadowOffset = CGSize(width: 0, height: 2.0)

        backgroundColor = nil
    }

    func removeShadow() {
        layer.shadowColor = nil
    }

    private func styleSelectedBorder(animated: Bool = false) {
        let imageBorderColor = isSelected ? accentColor.cgColor : borderColor.cgColor
        let imageBorderWidth = isSelected ? 2 : borderWith
        guard animated else {
            imageView.layer.borderColor = imageBorderColor
            imageView.layer.borderWidth = imageBorderWidth
            return
        }

        let borderWidthAnimation: CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
        borderWidthAnimation.fromValue = imageView.layer.borderWidth
        borderWidthAnimation.toValue = imageBorderWidth
        borderWidthAnimation.duration = CollapsableHeaderCollectionViewCell.selectionAnimationSpeed

        let borderColorAnimation: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        borderColorAnimation.fromValue = imageView.layer.borderColor
        borderColorAnimation.toValue = imageBorderColor
        borderColorAnimation.duration = CollapsableHeaderCollectionViewCell.selectionAnimationSpeed

        imageView.layer.add(borderColorAnimation, forKey: "borderColor")
        imageView.layer.add(borderWidthAnimation, forKey: "borderWidth")
        imageView.layer.borderColor = imageBorderColor
        imageView.layer.borderWidth = imageBorderWidth
    }

    private func checkmarkHidden(_ isHidden: Bool, animated: Bool = false) {
        guard animated else {
            checkmarkImageView.isHidden = isHidden
            checkmarkBackground.isHidden = isHidden
            return
        }

        checkmarkImageView.isHidden = false
        checkmarkBackground.isHidden = false

        // Set the inverse of the animation destination
        checkmarkImageView.alpha = isHidden ? 1 : 0
        checkmarkBackground.alpha = isHidden ? 1 : 0
        let targetAlpha: CGFloat = isHidden ? 0 : 1

        UIView.animate(withDuration: CollapsableHeaderCollectionViewCell.selectionAnimationSpeed, animations: {
            self.checkmarkImageView.alpha = targetAlpha
            self.checkmarkBackground.alpha = targetAlpha
        }, completion: { (_) in
            self.checkmarkImageView.isHidden = isHidden
            self.checkmarkBackground.isHidden = isHidden
        })
    }

    func setImage(_ imageURL: String?) {
        guard let imageURL = imageURL, let url = URL(string: imageURL) else { return }
        imageView.startGhostAnimation(style: GhostCellStyle.muriel)
        imageView.downloadImage(from: url, success: { [weak self] _ in
            self?.imageView.stopGhostAnimation()
        }, failure: { [weak self] error in
            self?.handleError(error, forURL: imageURL)
        })
    }

    /// This will retry the polling of the image URL in the situation where a mismatch was recieved for the requested image. This can happen for endpoints that
    /// dynamically generate the images. This will stop retrying if the view scrolled off screen. Or if the view was updated with a new URL to fetch. It will also stop
    /// retrying for any other error type.
    func handleError(_ error: Error?, forURL url: String?) {
        guard let error = error as? UIImageView.ImageDownloadError, error == .urlMismatch else { return }
        throttle.throttle { [weak self] in
            guard let self = self else { return }
            guard url != nil, url == self.previewURL else { return }
            self.setImage(url)
        }
    }
}
