import UIKit

class MediaEditorThumbCell: UICollectionViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!

    func showBorder() {
        layer.borderWidth = 1.5
        layer.borderColor = UIColor(red: 0.133, green: 0.443, blue: 0.694, alpha: 1).cgColor
    }

    func hideBorder() {
        layer.borderWidth = 0
    }
}
