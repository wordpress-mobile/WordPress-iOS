import UIKit

// UITableViewCell that displays a full width button with a border.
// Properties:
// - normalColor: used for the button label and border (if borderColor is not specified).
// - borderColor: used for border. Defaults to normalColor if not specified.
// - highlightedColor: used for the button label when the button is pressed.
// - buttonInsets: used to provide margins around the button within the cell.
// The delegate is notified when the button is tapped.

protocol BorderedButtonTableViewCellDelegate: AnyObject {
    func buttonTapped()
}

class BorderedButtonTableViewCell: UITableViewCell {

    // MARK: - Properties

    weak var delegate: BorderedButtonTableViewCellDelegate?

    private var buttonTitle = String()
    private var buttonInsets = Defaults.buttonInsets
    private var titleFont = Defaults.titleFont
    private var normalColor = Defaults.normalColor
    private var highlightedColor = Defaults.highlightedColor
    private var borderColor = Defaults.normalColor

    // Toggles the loading state of the cell.
    var isLoading: Bool = false {
        didSet {
            toggleLoading(isLoading)
        }
    }

    // MARK: - Activity Indicator

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = false
        return indicator
    }()

    private lazy var loadingBackgroundView: UIImageView = {
        // Bordered background matching the button
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage.renderBackgroundImage(fill: .clear, border: borderColor)
        return imageView
    }()

    private lazy var loadingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .basicBackground
        view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(loadingBackgroundView)
        view.pinSubviewToAllEdges(loadingBackgroundView)

        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)

        return view
    }()

    private lazy var button: UIButton = {
        let button = UIButton()

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(buttonTitle, for: .normal)

        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(highlightedColor, for: .highlighted)

        button.titleLabel?.font = titleFont
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        return button
    }()

    private lazy var jetpackBadge: JetpackButton = {
        let button = JetpackButton(style: .badge)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var jetpackBadgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(jetpackBadge)
        return view
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [button, jetpackBadgeView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    // MARK: - Configure

    func configure(buttonTitle: String,
                   titleFont: UIFont = Defaults.titleFont,
                   normalColor: UIColor = Defaults.normalColor,
                   highlightedColor: UIColor = Defaults.highlightedColor,
                   borderColor: UIColor? = nil,
                   buttonInsets: UIEdgeInsets = Defaults.buttonInsets) {
        self.buttonTitle = buttonTitle
        self.titleFont = titleFont
        self.normalColor = normalColor
        self.highlightedColor = highlightedColor
        self.borderColor = borderColor ?? normalColor
        self.buttonInsets = buttonInsets
        configureView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateButtonBorderColors()
        }
    }

}

// MARK: - Private Extension

private extension BorderedButtonTableViewCell {

    func configureView() {
        selectionStyle = .none
        accessibilityTraits = .button

        configureButton()
        configureJetpackBadge()
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView, insets: buttonInsets)
    }

    func configureButton() {
        // Add constraints to the title label, so the button can contain it properly in multi-line cases.
        if let label = button.titleLabel {
            button.pinSubviewToAllEdgeMargins(label)
        }

        button.on(.touchUpInside) { [weak self] _ in
            self?.delegate?.buttonTapped()
        }
        updateButtonBorderColors()
    }

    func configureJetpackBadge() {
        guard JetpackBrandingVisibility.all.enabled else {
            jetpackBadgeView.isHidden = true
            return
        }
        NSLayoutConstraint.activate([
            jetpackBadge.topAnchor.constraint(equalTo: jetpackBadgeView.topAnchor, constant: Defaults.jetpackBadgeTopInset),
            jetpackBadge.bottomAnchor.constraint(equalTo: jetpackBadgeView.bottomAnchor),
            jetpackBadge.centerXAnchor.constraint(equalTo: jetpackBadgeView.centerXAnchor)
        ])
    }

    func updateButtonBorderColors() {
        button.setBackgroundImage(.renderBackgroundImage(fill: .clear, border: borderColor), for: .normal)
        button.setBackgroundImage(.renderBackgroundImage(fill: borderColor, border: borderColor), for: .highlighted)
    }

    struct Defaults {
        static let buttonInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let titleFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        static let normalColor: UIColor = .text
        static let highlightedColor: UIColor = .textInverted
        static let jetpackBadgeTopInset: CGFloat = 30
    }

    func toggleLoading(_ loading: Bool) {
        if loadingOverlayView.superview == nil {
            button.addSubview(loadingOverlayView)
            button.pinSubviewToAllEdges(loadingOverlayView)
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
