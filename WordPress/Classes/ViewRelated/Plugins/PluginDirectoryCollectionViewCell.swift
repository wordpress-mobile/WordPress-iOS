import UIKit
import WordPressKit

class PluginDirectoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!

    var accessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()

            guard let view = accessoryView else { return }

            self.addSubview(view)

            view.topAnchor.constraint(greaterThanOrEqualTo: authorLabel.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.font = WPStyleGuide.subtitleFontBold()
        logoImageView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        accessoryView?.removeFromSuperview()
        logoImageView.cancelImageDownloadTask()
    }

}
