import UIKit
import Gridicons

/// A view that consists of the frame of a Dashboard card
/// Title, icon and action can be customizable
class BlogDashboardCardFrameView: UIView {

    /// The main stack view, in which the header and the content
    /// are appended to.
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// Header in which icon, title and chevron are added
    private lazy var headerStackView: UIStackView = {
        let topStackView = UIStackView()
        topStackView.layoutMargins = Constants.headerPadding
        topStackView.isLayoutMarginsRelativeArrangement = true
        topStackView.spacing = Constants.headerHorizontalSpacing
        topStackView.alignment = .center
        topStackView.axis = .horizontal
        return topStackView
    }()

    /// Card's icon image view
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView(image: UIImage.gridicon(.posts, size: Constants.iconSize).withRenderingMode(.alwaysTemplate))
        iconImageView.tintColor = .label
        iconImageView.frame = CGRect(x: 0, y: 0, width: Constants.iconSize.width, height: Constants.iconSize.height)
        iconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        iconImageView.isAccessibilityElement = false
        return iconImageView
    }()

    /// Card's title
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        titleLabel.accessibilityTraits = .button
        return titleLabel
    }()

    /// Chevron displayed in case there's any action associa
    private lazy var chevronImageView: UIImageView = {
        let chevronImageView = UIImageView(image: UIImage.gridicon(.chevronRight, size: Constants.iconSize).withRenderingMode(.alwaysTemplate))
        chevronImageView.frame = CGRect(x: 0, y: 0, width: Constants.iconSize.width, height: Constants.iconSize.height)
        chevronImageView.tintColor = .listIcon
        chevronImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        chevronImageView.isAccessibilityElement = false
        chevronImageView.isHidden = true
        return chevronImageView
    }()

    weak var currentView: UIView?

    /// The title at the header
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    /// The icon to be displayed at the header
    var icon: UIImage? {
        didSet {
            iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        }
    }

    /// Closure to be called when anywhere in the view is tapped.
    /// If set, the chevron image is displayed.
    var onViewTap: (() -> Void)? {
        didSet {
            chevronImageView.isHidden = onViewTap == nil && onHeaderTap == nil
        }
    }

    /// Closure to be called when the header view is tapped.
    /// If set, this overrides the `onViewTap` closure if the tap is inside the header.
    /// If set, the chevron image is displayed.
    var onHeaderTap: (() -> Void)? {
        didSet {
            chevronImageView.isHidden = onViewTap == nil && onHeaderTap == nil
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .listForeground

        layer.cornerRadius = Constants.cornerRadius

        configureStackViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Add a subview inside the card frame
    func add(subview: UIView) {
        mainStackView.addArrangedSubview(subview)
        currentView = subview
    }

    /// Hide the header
    func hideHeader() {
        headerStackView.isHidden = true
    }

    /// Hide the header
    func showHeader() {
        headerStackView.isHidden = false
    }

    private func configureStackViews() {
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView, insets: UIEdgeInsets(top: 0, left: 0, bottom: Constants.bottomPadding, right: 0))

        mainStackView.addArrangedSubview(headerStackView)

        headerStackView.addArrangedSubviews([
            iconImageView,
            titleLabel,
            chevronImageView
        ])

        // Add frame tap gesture
        let frameTapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.addGestureRecognizer(frameTapGesture)

        // Add header tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        headerStackView.addGestureRecognizer(tap)
    }

    @objc private func viewTapped() {
        onViewTap?()
    }

    @objc private func headerTapped() {
        if let onHeaderTap = onHeaderTap {
            onHeaderTap()
        }
        else {
            onViewTap?()
        }

    }

    private enum Constants {
        static let bottomPadding: CGFloat = 8
        static let headerPadding = UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)
        static let headerHorizontalSpacing: CGFloat = 5
        static let iconSize = CGSize(width: 18, height: 18)
        static let cornerRadius: CGFloat = 10
    }
}
