import UIKit

/// A centered, single button cell with optional icon displayed on the left side.
///
/// The component is built using a `UILabel` and `UIImageView` instead of `UIButton`,
/// because UIButton would prevent `tableView(_:didSelectRowAt:)` from triggering properly.
///
/// Views are properly configured to react to `tintColor` changes.
///
class SingleButtonTableViewCell: WPReusableTableViewCell, NibLoadable {

    // MARK: Public Properties

    var title: String? = nil {
        didSet {
            buttonLabel.text = title
        }
    }

    var iconImage: UIImage? = nil {
        didSet {
            guard let someImage = iconImage else {
                toggleIcon(visible: false)
                return
            }

            iconImageView.image = someImage.withRenderingMode(.alwaysTemplate)
            toggleIcon(visible: true)
        }
    }

    // MARK: IBOutlets

    @IBOutlet private weak var buttonLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet weak var labelCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconTrailingConstraint: NSLayoutConstraint!

    // MARK: Initialization

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    override func tintColorDidChange() {
        buttonLabel.textColor = tintColor
        iconImageView.tintColor = tintColor
    }
}

// MARK: - Private Helpers

private extension SingleButtonTableViewCell {

    func setupViews() {
        selectionStyle = .none

        // hide the icon initially.
        toggleIcon(visible: false)
        iconImageView.tintColor = tintColor
        iconImageView.adjustsImageSizeForAccessibilityContentSizeCategory = true

        buttonLabel.adjustsFontForContentSizeCategory = true
        buttonLabel.adjustsFontSizeToFitWidth = true
        buttonLabel.font = WPStyleGuide.tableviewTextFont()
        buttonLabel.textColor = tintColor
        buttonLabel.numberOfLines = 0
    }

    func toggleIcon(visible: Bool) {
        iconImageView.isHidden = !visible

        // adjust the label's center alignment when the icon is visible, to make the button properly centered.
        let adjustmentValue = (iconImageView.frame.width + iconTrailingConstraint.constant) / 2
        labelCenterXConstraint.constant = visible ? adjustmentValue : 0
    }

}
