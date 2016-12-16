import UIKit
import WordPressShared

class FeatureItemCell: WPTableViewCell {
    @IBOutlet weak var featureIconImageView: UIImageView!
    @IBOutlet weak var featureTitleLabel: UILabel!
    @IBOutlet weak var featureDescriptionLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet var separatorEdgeConstraints: [NSLayoutConstraint]!

    override var separatorInset: UIEdgeInsets {
        didSet {
            for constraint in separatorEdgeConstraints {
                if constraint.firstAttribute == .leading {
                    constraint.constant = separatorInset.left
                } else if constraint.firstAttribute == .trailing {
                    constraint.constant = separatorInset.right
                }
            }

            separator.layoutIfNeeded()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layoutMargins = UIEdgeInsets.zero

        separator.backgroundColor = WPStyleGuide.greyLighten30()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        separator.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // This is required to fix an issue where only the first line of text would
        // is displayed on the iPhone 6(s) Plus due to a fractional Y position.
        featureDescriptionLabel.frame = featureDescriptionLabel.frame.integral
    }
}
