import UIKit

class SelectThemeCell: UICollectionViewCell {

    open static let reuseIdentifier = "themeSelectionCell"

    @IBOutlet weak var themeImageView: UIImageView!
    @IBOutlet weak var themeTitleLabel: UILabel!

    override open func awakeFromNib() {
        super.awakeFromNib()
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
    }
}
