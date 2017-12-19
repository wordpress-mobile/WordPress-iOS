import UIKit

extension UICollectionViewCell {
    // Allows cell tint color to be set via UIAppearance
    @objc func setCellTintColor(_ color: UIColor) {
        tintColor = color
    }
}
