import UIKit

/// A centered, single button cell with optional icon displayed on the left side.
///
/// The component is built using a `UILabel` and `UIImageView` instead of `UIButton`,
/// because UIButton would prevent `tableView(_:didSelectRowAt:)` from triggering properly.
///
/// Views are properly configured to react to `tintColor` changes.
///
class SingleButtonTableViewCell: WPReusableTableViewCell {

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

    // TODO: (Low) Pull in centerX constraint and adjust as the image view is hidden?

    // MARK: Initialization

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    // TODO: Test if this changes the color properly.
    override func tintColorDidChange() {
        buttonLabel.textColor = tintColor
        iconImageView.tintColor = tintColor
    }
}

// MARK: - Private Helpers

private extension SingleButtonTableViewCell {

    func setupViews() {
        buttonLabel.adjustsFontForContentSizeCategory = true
        buttonLabel.adjustsFontSizeToFitWidth = true
        buttonLabel.font = WPStyleGuide.tableviewTextFont()
        buttonLabel.textColor = tintColor
        buttonLabel.numberOfLines = 0

        // hide the icon initially.
        iconImageView.isHidden = true
        iconImageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
    }

    func toggleIcon(visible: Bool) {
        iconImageView.isHidden = !visible

        // TODO: (Low) Adjust label center X constraints.
        // labelCenterXConstraint.constant = visible ? iconImageView.frame.width / 2 : 0
    }

}
