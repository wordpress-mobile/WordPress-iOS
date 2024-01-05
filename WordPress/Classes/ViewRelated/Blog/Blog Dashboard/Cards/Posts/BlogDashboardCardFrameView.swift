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

    /// Card's title
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        titleLabel.accessibilityTraits = .button
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    /// Ellipsis Button displayed on the top right corner of the view.
    /// Displayed only when an associated action is set
    private(set) lazy var ellipsisButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "more-horizontal-mobile"), for: .normal)
        button.tintColor = UIColor.listIcon
        button.contentEdgeInsets = Constants.ellipsisButtonPadding
        button.isAccessibilityElement = true
        button.accessibilityLabel = Strings.ellipsisButtonAccessibilityLabel
        button.accessibilityTraits = .button
        button.isHidden = true
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.on([.touchUpInside, .menuActionTriggered]) { [weak self] _ in
            self?.onEllipsisButtonTap?()
        }
        return button
    }()

    /// Button container stack view anchored to the top right corner of the view.
    /// Displayed only when the header view is hidden.
    private(set) lazy var buttonContainerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.axis = .horizontal
        return containerStackView
    }()

    private var mainStackViewTrailingConstraint: NSLayoutConstraint?

    weak var currentView: UIView?

    /// Closure to be called when anywhere in the view is tapped.
    /// If set, the chevron image is displayed.
    var onViewTap: (() -> Void)? {
        didSet {
            addViewTapGestureIfNeeded()
        }
    }

    /// Closure to be called when the header view is tapped.
    /// If set, this overrides the `onViewTap` closure if the tap is inside the header.
    /// If set, the chevron image is displayed.
    var onHeaderTap: (() -> Void)? {
        didSet {
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
        self.backgroundColor = .listForeground
        self.configureMainStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        // Update view background
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Constants.cornerRadius
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

        if !ellipsisButton.isHidden {
            mainStackViewTrailingConstraint?.constant = -Constants.mainStackViewTrailingPadding
        }
    }

    /// Hide the header
    func showHeader() {
        headerStackView.isHidden = false
        buttonContainerStackView.isHidden = true

        mainStackViewTrailingConstraint?.constant = 0
    }


    /// Set's the title displayed in the card's header
    /// - Parameters:
    ///   - title: Title to be displayed
    ///   - titleHint: The part in the title that needs to be highlighted
    func setTitle(_ title: String?, titleHint: String? = nil) {
        guard let title else {
            return
        }
        self.titleLabel.attributedText = Self.titleAttributedText(title: title, hint: titleHint, font: titleLabel.font)
    }

    private func configureMainStackView() {
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
        headerStackView.addArrangedSubviews([titleLabel, ellipsisButton])
    }

    /// Configures button container stack view
    /// Only call when the header view is hidden
    func configureButtonContainerStackView() {
        addSubview(buttonContainerStackView)

        NSLayoutConstraint.activate([
            buttonContainerStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.buttonContainerStackViewPadding),
            buttonContainerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.buttonContainerStackViewPadding)
        ])

        buttonContainerStackView.addArrangedSubviews([
            ellipsisButton
        ])
    }

    func removeButtonContainerStackView() {
        buttonContainerStackView.removeFromSuperview()
    }

    /// Adds the "more" button with the given actions to the corner of the cell.
    func addMoreMenu(items: [UIMenuElement], card: DashboardCard) {
        self.addMoreMenu(items: items, card: card as BlogDashboardAnalyticPropertiesProviding)
    }

    /// Adds the "more" button with the given actions to the corner of the cell.
    func addMoreMenu(items: [UIMenuElement], card: BlogDashboardAnalyticPropertiesProviding) {
        onEllipsisButtonTap = {
            BlogDashboardAnalytics.trackContextualMenuAccessed(for: card)
        }
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = UIMenu(title: "", options: .displayInline, children: items)
    }

    private func updateEllipsisButtonState() {
        ellipsisButton.isHidden = onEllipsisButtonTap == nil
        let headerPadding = ellipsisButton.isHidden ?
            Constants.headerPaddingWithEllipsisButtonHidden :
            Constants.headerPaddingWithEllipsisButtonShown
        headerStackView.layoutMargins = headerPadding
    }

    private func addHeaderTapGestureIfNeeded() {
        // Reset any previously added gesture recognizers
        headerStackView.gestureRecognizers?.forEach { headerStackView.removeGestureRecognizer($0) }

        // Add gesture recognizer if needed
        if onHeaderTap != nil {
            let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
            headerStackView.addGestureRecognizer(tap)
        }
    }

    private func addViewTapGestureIfNeeded() {
        // Reset any previously added gesture recognizers
        self.gestureRecognizers?.forEach { self.removeGestureRecognizer($0) }

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

    private static func titleAttributedText(title: String, hint: String?, font: UIFont?) -> NSAttributedString {
        let titleString = NSMutableAttributedString(string: title)
        if let hint = hint, let range = title.nsRange(of: hint) {
            titleString.addAttributes([
                .foregroundColor: UIColor.primary,
                .font: font as Any
            ], range: range)
        }
        return titleString
    }

    private enum Constants {
        static let bottomPadding: CGFloat = 8
        static let headerPaddingWithEllipsisButtonHidden = UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)
        static let headerPaddingWithEllipsisButtonShown = UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 8)
        static let headerHorizontalSpacing: CGFloat = 5
        static let cornerRadius: CGFloat = 10
        static let ellipsisButtonPadding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        static let buttonContainerStackViewPadding: CGFloat = 8
        static let mainStackViewTrailingPadding: CGFloat = 32
    }

    private enum Strings {
        static let ellipsisButtonAccessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for more button in dashboard quick start card.")
    }
}
