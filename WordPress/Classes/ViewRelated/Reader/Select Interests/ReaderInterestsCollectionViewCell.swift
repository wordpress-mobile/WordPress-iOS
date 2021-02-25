import UIKit

class ReaderInterestsCollectionViewCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        guard let label = self.label else {
            return
        }

        label.isAccessibilityElement = true
        accessibilityElements = [label]
    }

}
