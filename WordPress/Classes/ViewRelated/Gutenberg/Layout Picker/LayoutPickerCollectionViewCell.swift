import UIKit
import Gutenberg
import Gridicons

class LayoutPickerCollectionViewCell: UICollectionViewCell {

    static let cellReuseIdentifier = "LayoutPickerCollectionViewCell"
    static let nib = UINib(nibName: "LayoutPickerCollectionViewCell", bundle: Bundle.main)

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
            styleSelectedBorderColor()
            imageView.layer.borderWidth = isSelected ? 2 : borderWith
            checkmarkImageView.isHidden = !isSelected
            checkmarkBackground.isHidden = !isSelected
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleSelectedBorderColor()
        imageView.layer.borderWidth = borderWith

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
                styleSelectedBorderColor()
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

    private func styleSelectedBorderColor() {
        imageView.layer.borderColor = isSelected ? accentColor.cgColor : borderColor.cgColor
    }

    func setImage(_ imageURL: String?) {
        guard let imageURL = imageURL, let url = URL(string: imageURL) else { return }
        imageView.startGhostAnimation()
        imageView.downloadImage(from: url, success: { [weak self] _ in
            self?.imageView.stopGhostAnimation()
        }, failure: nil)
    }
}
