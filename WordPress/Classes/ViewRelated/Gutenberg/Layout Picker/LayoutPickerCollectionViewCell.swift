import UIKit
import Gutenberg
import Gridicons

class LayoutPickerCollectionViewCell: UICollectionViewCell {

    static let cellReuseIdentifier = "LayoutPickerCollectionViewCell"
    static let nib = UINib(nibName: "LayoutPickerCollectionViewCell", bundle: Bundle.main)
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

    var layout: PageTemplateLayout? = nil {
        didSet {
            setImage(layout?.preview)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelImageDownload()
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
        borderWidthAnimation.duration = LayoutPickerCollectionViewCell.selectionAnimationSpeed

        let borderColorAnimation: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        borderColorAnimation.fromValue = imageView.layer.borderColor
        borderColorAnimation.toValue = imageBorderColor
        borderColorAnimation.duration = LayoutPickerCollectionViewCell.selectionAnimationSpeed

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

        UIView.animate(withDuration: LayoutPickerCollectionViewCell.selectionAnimationSpeed, animations: {
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
        }, failure: nil)
    }
}
