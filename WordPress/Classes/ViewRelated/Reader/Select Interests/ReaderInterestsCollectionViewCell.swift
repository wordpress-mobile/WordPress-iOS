import UIKit

class ReaderInterestsCollectionViewCell: UICollectionViewCell, NibReusable {
    @IBOutlet weak var label: UILabel!

    /// The border color. `layer.borderColor` is a `CGColor`, which doesn't follow light and dark mode,
    /// so the cell keeps the dynamic color and resolves it again whenever the interface style changes.
    var borderColor: UIColor? {
        didSet { updateBorderColor() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBorderColor()
        }

        guard let label = self.label else {
            return
        }

        label.isAccessibilityElement = true
        accessibilityElements = [label]
    }

    private func updateBorderColor() {
        layer.borderColor = borderColor?.resolvedColor(with: traitCollection).cgColor
    }
}
