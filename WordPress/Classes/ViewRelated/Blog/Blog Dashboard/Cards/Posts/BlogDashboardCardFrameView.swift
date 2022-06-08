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
        topStackView.layoutMargins = Constants.headerPaddingWithEllipsisButtonHidden
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

    /// Chevron displayed in case there's any action associated
    private lazy var chevronImageView: UIImageView = {
        let chevronImage = UIImage.gridicon(.chevronRight, size: Constants.iconSize).withRenderingMode(.alwaysTemplate)
        let chevronImageView = UIImageView(image: chevronImage.imageFlippedForRightToLeftLayoutDirection())
        chevronImageView.frame = CGRect(x: 0, y: 0, width: Constants.iconSize.width, height: Constants.iconSize.height)
        chevronImageView.tintColor = .listIcon
        chevronImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        chevronImageView.isAccessibilityElement = false
        chevronImageView.isHidden = true
        chevronImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return chevronImageView
    }()

    /// Ellipsis Button displayed on the top right corner of the view.
    /// Displayed only when an associated action is set
    private(set) lazy var ellipsisButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.gridicon(.ellipsis).imageWithTintColor(.listIcon), for: .normal)
        button.contentEdgeInsets = Constants.ellipsisButtonPadding
        button.isAccessibilityElement = true
        button.accessibilityLabel = Strings.ellipsisButtonAccessibilityLabel
        button.accessibilityTraits = .button
        button.isHidden = true
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.on(.touchUpInside) { [weak self] _ in
            self?.onEllipsisButtonTap?()
        }
        return button
    }()

    /// Button container stack view anchored to the top right corner of the view.
    /// Displayed only when the header view is hidden.
    private lazy var buttonContainerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.axis = .horizontal
        return containerStackView
    }()

    private var mainStackViewTrailingConstraint: NSLayoutConstraint?

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
            updateChevronImageState()
            addViewTapGestureIfNeeded()
        }
    }

    /// Closure to be called when the header view is tapped.
    /// If set, this overrides the `onViewTap` closure if the tap is inside the header.
    /// If set, the chevron image is displayed.
    var onHeaderTap: (() -> Void)? {
        didSet {
            updateChevronImageState()
            addHeaderTapGestureIfNeeded()
        }

    }

    /// Closure to be called when the ellipsis button is tapped..
    /// If set, the ellipsis button image is displayed.
    var onEllipsisButtonTap: (() -> Void)? {
        didSet {
            updateEllipsisButtonState()
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    /// Add a subview inside the card frame
    func add(subview: UIView) {
        mainStackView.addArrangedSubview(subview)
        currentView = subview
    }

    /// Hide the header
    func hideHeader() {
        headerStackView.isHidden = true
        buttonContainerStackView.isHidden = false

        if !ellipsisButton.isHidden || !chevronImageView.isHidden {
            mainStackViewTrailingConstraint?.constant = -Constants.mainStackViewTrailingPadding
        }
    }

    /// Hide the header
    func showHeader() {
        headerStackView.isHidden = false
        buttonContainerStackView.isHidden = true

        mainStackViewTrailingConstraint?.constant = 0
    }

    private func configureStackViews() {
        addSubview(mainStackView)

        let trailingConstraint = mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        mainStackViewTrailingConstraint = trailingConstraint

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomPadding),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingConstraint
        ])

        mainStackView.addArrangedSubview(headerStackView)

        headerStackView.addArrangedSubviews([
            iconImageView,
            titleLabel,
            chevronImageView,
            ellipsisButton
        ])

        addSubview(buttonContainerStackView)

        NSLayoutConstraint.activate([
            buttonContainerStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.buttonContainerStackViewPadding),
            buttonContainerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.buttonContainerStackViewPadding)
        ])

        buttonContainerStackView.addArrangedSubviews([
            chevronImageView,
            ellipsisButton
        ])
    }

    private func updateColors() {
        ellipsisButton.setImage(UIImage.gridicon(.ellipsis).imageWithTintColor(.listIcon), for: .normal)
    }

    private func updateChevronImageState() {
        chevronImageView.isHidden = onViewTap == nil && onHeaderTap == nil
        assertOnTapRecognitionCorrectUsage()
    }

    private func updateEllipsisButtonState() {
        ellipsisButton.isHidden = onEllipsisButtonTap == nil
        let headerPadding = ellipsisButton.isHidden ?
            Constants.headerPaddingWithEllipsisButtonHidden :
            Constants.headerPaddingWithEllipsisButtonShown
        headerStackView.layoutMargins = headerPadding
        assertOnTapRecognitionCorrectUsage()
    }

    /// Only one of two types of action should be associated with the card.
    /// Either ellipsis button tap, or view/header tap
    private func assertOnTapRecognitionCorrectUsage() {
        let bothTypesUsed = (onViewTap != nil || onHeaderTap != nil) && onEllipsisButtonTap != nil
        assert(!bothTypesUsed, "Using onViewTap or onHeaderTap alongside onEllipsisButtonTap is not supported and will result in unexpected behavior.")
    }

    private func addHeaderTapGestureIfNeeded() {
        // Reset any previously added gesture recognizers
        headerStackView.gestureRecognizers?.forEach {headerStackView.removeGestureRecognizer($0)}

        // Add gesture recognizer if needed
        if onHeaderTap != nil {
            let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
            headerStackView.addGestureRecognizer(tap)
        }
    }

    private func addViewTapGestureIfNeeded() {
        // Reset any previously added gesture recognizers
        self.gestureRecognizers?.forEach {self.removeGestureRecognizer($0)}

        // Add gesture recognizer if needed
        if onViewTap != nil {
            let frameTapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
            self.addGestureRecognizer(frameTapGesture)
        }
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
        static let headerPaddingWithEllipsisButtonHidden = UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)
        static let headerPaddingWithEllipsisButtonShown = UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 8)
        static let headerHorizontalSpacing: CGFloat = 5
        static let iconSize = CGSize(width: 18, height: 18)
        static let cornerRadius: CGFloat = 10
        static let ellipsisButtonPadding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        static let buttonContainerStackViewPadding: CGFloat = 8
        static let mainStackViewTrailingPadding: CGFloat = 32
    }

    private enum Strings {
        static let ellipsisButtonAccessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for more button in dashboard quick start card.")
    }
}
