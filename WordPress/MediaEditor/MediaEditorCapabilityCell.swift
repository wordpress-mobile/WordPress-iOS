import UIKit

class MediaEditorCapabilityCell: UICollectionViewCell {
    @IBOutlet weak var iconButton: UIButton!

    func configure(_ capabilityInfo: (String, UIImage)) {
        let (name, icon) = capabilityInfo
        iconButton.setImage(icon, for: .normal)
        iconButton.accessibilityHint = name
    }
}
