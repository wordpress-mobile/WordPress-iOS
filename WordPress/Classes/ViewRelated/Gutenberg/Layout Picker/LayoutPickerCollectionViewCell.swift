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
    @IBOutlet weak var previewLoadingView: UIActivityIndicatorView!
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

    override func awakeFromNib() {
        super.awakeFromNib()
        addShadow()
        imageView.layer.borderColor = accentColor.cgColor
    }

    override var isSelected: Bool {
        didSet {
            imageView.layer.borderWidth = isSelected ? 2 : 0
            checkmarkImageView.isHidden = !isSelected
            checkmarkBackground.isHidden = !isSelected
        }
    }

    func addShadow() {
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3.0)
        layer.shadowRadius = 7.0
        layer.shadowOpacity = 1.0
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        layer.backgroundColor = UIColor.clear.cgColor
    }

    func setImage(_ imageURL: String?) {
        guard let imageURL = imageURL, let url = URL(string: imageURL) else { return }
        previewLoadingView.startAnimating()
        imageView.downloadImage(from: url, success: { _ in
            self.stopProgressBar()
        }, failure: { _ in
            self.stopProgressBar()
        })
    }

    func stopProgressBar() {
        DispatchQueue.main.async {
            self.previewLoadingView.stopAnimating()
        }
    }
}
