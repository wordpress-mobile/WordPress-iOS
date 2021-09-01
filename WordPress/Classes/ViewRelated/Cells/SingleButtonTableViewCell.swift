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
            accessibilityLabel = title
        }
    }

    var iconImage: UIImage? = nil {
        didSet {
            guard let someImage = iconImage else {
                iconImageView.isHidden = true
                return
            }

            iconImageView.image = someImage.withRenderingMode(.alwaysTemplate)
            iconImageView.isHidden = false
        }
    }

    /// Toggles the loading state of the cell.
    var isLoading: Bool = false {
        didSet {
            toggleLoading(isLoading)
        }
    }

    // MARK: IBOutlets

    @IBOutlet private weak var buttonLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!

    // MARK: Activity Indicator

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = false
        return indicator
    }()

    private lazy var loadingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .listForeground
        view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)
        return view
    }()

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
        accessibilityTraits = .button

        // hide the image view initially.
        iconImageView.isHidden = true
        iconImageView.tintColor = tintColor
        iconImageView.adjustsImageSizeForAccessibilityContentSizeCategory = true

        buttonLabel.adjustsFontForContentSizeCategory = true
        buttonLabel.adjustsFontSizeToFitWidth = true
        buttonLabel.font = WPStyleGuide.tableviewTextFont()
        buttonLabel.textColor = tintColor
        buttonLabel.numberOfLines = 0
    }

    func toggleLoading(_ loading: Bool) {
        if loadingOverlayView.superview == nil {
            contentView.addSubview(loadingOverlayView)
            contentView.pinSubviewToAllEdges(loadingOverlayView)
        }

        if loading {
            activityIndicator.startAnimating()
            bringSubviewToFront(loadingOverlayView)
        } else {
            activityIndicator.stopAnimating()
            sendSubviewToBack(loadingOverlayView)
        }

        loadingOverlayView.isHidden = !loading
    }

}
