import UIKit
import WordPressKit


class PluginDirectoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.font = WPStyleGuide.subtitleFontBold()
        logoImageView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        logoImageView.image = nil
    }

}
