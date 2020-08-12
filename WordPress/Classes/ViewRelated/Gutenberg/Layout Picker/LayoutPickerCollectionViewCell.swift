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
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleSelectedBorderColor()
            }
        }
    }

    private func styleSelectedBorderColor() {
        imageView.layer.borderColor = isSelected ? accentColor.cgColor : borderColor.cgColor
    }

    func setImage(_ imageURL: String?) {
        guard let imageURL = imageURL, let url = URL(string: imageURL) else { return }
        imageView.downloadImage(from: url, success: nil, failure: nil)
    }
}
