import UIKit

class MediaEditorThumbCell: UICollectionViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!

    func showBorder(color: UIColor? = nil) {
        layer.borderWidth = 5
        layer.borderColor = color?.cgColor ?? Constant.defaultSelectedColor
    }

    func hideBorder() {
        layer.borderWidth = 0
    }

    private enum Constant {
        static var defaultSelectedColor = UIColor(red: 0.133, green: 0.443, blue: 0.694, alpha: 1).cgColor
    }
}
