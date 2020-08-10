import UIKit
import Gutenberg
import Gridicons

class LayoutPickerCollectionViewCell: UICollectionViewCell {

    static var cellReuseIdentifier: String {
         return "LayoutPickerCollectionViewCell"
     }

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerCollectionViewCell", bundle: Bundle.main)
    }

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

    var layout: GutenbergLayout? = nil {
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

    override var isSelected: Bool {
        didSet {
            imageView.layer.borderWidth = isSelected ? 2 : 0
            checkmarkImageView.isHidden = !isSelected
            checkmarkBackground.isHidden = !isSelected
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleUI()
            }
        }
    }

    private func styleUI() {
        if #available(iOS 13.0, *) {
            styleShadow()
        } else {
            styleShadowLightMode()
        }
        imageView.layer.borderColor = accentColor.cgColor
    }

    @available(iOS 13.0, *)
    func styleShadow() {
        if traitCollection.userInterfaceStyle == .dark {
            styleShadowDarkMode()
        } else {
            styleShadowLightMode()
        }
    }

    func styleShadowLightMode() {
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3.0)
        layer.shadowRadius = 7.0
        layer.shadowOpacity = 1.0
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        layer.backgroundColor = UIColor.clear.cgColor
    }

    func styleShadowDarkMode() {
        layer.shadowColor = nil
        layer.shadowOffset = CGSize(width: 0, height: -3.0)
        layer.shadowRadius = 0.0
        layer.shadowOpacity = 0.0
        layer.masksToBounds = true
        layer.shadowPath = nil
        layer.backgroundColor = UIColor.clear.cgColor
    }

    func setImage(_ imageURL: String?) {
        guard let imageURL = imageURL, let url = URL(string: imageURL) else { return }
        imageView.downloadImage(from: url, success: { _ in
        }, failure: { _ in
        })
    }
}
