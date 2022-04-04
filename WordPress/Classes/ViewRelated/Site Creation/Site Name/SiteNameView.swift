
import UIKit
import WordPressShared

/// content view for SiteNameViewController
class SiteNameView: UIView {

    private let siteName: String

    // MARK: UI

    /// Title
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .semibold)
        label.numberOfLines = Metrics.numberOfLinesInTitle
        label.textAlignment = .center
        return label
    }()

    // used to add left and right padding to the title
    private lazy var titleLabelView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        return view
    }()

    /// Subtitle
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = .secondaryLabel
        label.setText(TextContent.subtitle)
        label.numberOfLines = Metrics.numberOfLinesInSubtitle
        label.textAlignment = .center
        return label
    }()

    // used to add left and right padding to the subtitle
    private lazy var subtitleLabelView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        return view
    }()

    /// Search bar
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        WPStyleGuide.configureSearchBar(searchBar)
        searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchBar.backgroundColor = .clear
        return searchBar
    }()

    /// Main stack view
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabelView, subtitleLabelView, searchBar])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.stackViewVerticalSpacing
        return stackView
    }()

    /// Continue button
    private lazy var continueButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        button.setTitle(TextContent.continueButtonTitle, for: .normal)
        //button.addTarget(self, action: #selector(navigateToNextStep), for: .touchUpInside)
        return button
    }()

    private lazy var continueButtonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(continueButton)
        return view
    }()

    init(siteName: String) {
        self.siteName = siteName
        super.init(frame: .zero)
        backgroundColor = .basicBackground
        addSubview(mainStackView)
        setupTitleColors()
        setupContinueButton()
        activateConstraints()
        searchBar.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        titleLabelView.isHidden = traitCollection.verticalSizeClass == .compact
        subtitleLabelView.isHidden = traitCollection.verticalSizeClass == .compact
    }
}

// MARK: setup
private extension SiteNameView {

    /// Highlghts the site name in blue
    func setupTitleColors() {
        let fullTitle = String(format: TextContent.title, siteName)
        let attributedTitle = NSMutableAttributedString(string: fullTitle)
        guard let range = fullTitle.nsRange(of: siteName) else {
            titleLabel.setText(TextContent.defaultTitle)
            return
        }
        attributedTitle.addAttributes([
            .foregroundColor: UIColor.primary,
        ], range: range)
        titleLabel.attributedText = attributedTitle
    }

    /// sets up the continue button on top of the keyboard
    func setupContinueButton() {
        continueButton.isEnabled = false
        WPStyleGuide.configureSearchBar(searchBar, returnKeyType: .continue)
        searchBar.searchTextField.inputAccessoryView = continueButtonView
        continueButtonView.frame = Metrics.continueButtonViewFrame(frame.width)

    }

    func activateConstraints() {
        continueButtonView.pinSubviewToSafeArea(continueButton, insets: Metrics.continueButtonInsets)
        titleLabelView.pinSubviewToAllEdges(titleLabel, insets: Metrics.titlesInsets)
        subtitleLabelView.pinSubviewToAllEdges(subtitleLabel, insets: Metrics.titlesInsets)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.titleTopSpacing),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: Metrics.searchbarHeight),
        ])
    }
}

// MARK: appearance
private extension SiteNameView {

    enum TextContent {
        static let title = NSLocalizedString("Give your %@ website a name",
                                             comment: "Title of the Site Name screen.")
        static let defaultTitle = NSLocalizedString("Give your website a name",
                                                    comment: "Default title of the Site Name screen.")
        static let subtitle = NSLocalizedString("A good name is short and memorable.\nYou can change it later",
                                                comment: "Subtitle of the Site Name screen.")
        static let continueButtonTitle = NSLocalizedString("Continue",
                                                           comment: "Title of the Continue button in the Site Name screen.")
    }

    enum Metrics {
        static let stackViewVerticalSpacing: CGFloat = 18
        static let searchbarHeight: CGFloat = 56
        static let titleTopSpacing: CGFloat = 10
        static let numberOfLinesInTitle = 0
        static let numberOfLinesInSubtitle = 0
        static let titlesInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let continueButtonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        static func continueButtonViewFrame(_ accessoryWidth: CGFloat) -> CGRect {
            CGRect(x: 0, y: 0, width: accessoryWidth, height: 76)
        }
    }

}

// MARK: search bar delegate
extension SiteNameView: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        continueButton.isEnabled = !searchText.isEmpty
    }
}
