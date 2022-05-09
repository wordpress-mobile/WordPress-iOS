
import UIKit
import WordPressShared

/// content view for SiteNameViewController
class SiteNameView: UIView {

    private var siteVerticalName: String
    private let onContinue: (String?) -> Void

    // Continue button constraints: will always be set in the initialzer, so it's fine to implicitly unwrap
    private var continueButtonTopConstraint: NSLayoutConstraint!
    private var continueButtonBottomConstraint: NSLayoutConstraint!
    private var continueButtonLeadingConstraint: NSLayoutConstraint!
    private var continueButtonTrailingConstraint: NSLayoutConstraint!

    // MARK: UI

    /// Title
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .semibold)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = Metrics.numberOfLinesInTitle
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = Metrics.titleMinimumScaleFactor
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
        label.adjustsFontForContentSizeCategory = true
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
        WPStyleGuide.configureSearchBar(searchBar, backgroundColor: .clear, returnKeyType: .continue)
        searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchBar.autocapitalizationType = .sentences
        searchBar.accessibilityIdentifier = "Website Title"
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString()
        return searchBar
    }()

    /// Main stack view
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabelView, subtitleLabelView, searchBar])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.mainStackViewVerticalSpacing
        return stackView
    }()

    /// Continue button
    private lazy var continueButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        button.setTitle(TextContent.continueButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(navigateToNextScreen), for: .touchUpInside)
        return button
    }()

    @objc private func navigateToNextScreen() {
        onContinue(searchBar.text)
    }

    private lazy var continueButtonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(continueButton)
        return view
    }()

    override var canBecomeFirstResponder: Bool {
        return true
    }

    init(siteVerticalName: String, onContinue: @escaping (String?) -> Void) {
        self.siteVerticalName = siteVerticalName
        self.onContinue = onContinue
        super.init(frame: .zero)
        backgroundColor = .basicBackground
        addSubview(mainStackView)
        setupTitleColors()
        setupContinueButton()
        activateConstraints()
        searchBar.delegate = self
        hideTitlesIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        hideTitlesIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateContinueButton()
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return searchBar.becomeFirstResponder()
    }
}

// MARK: setup
private extension SiteNameView {

    /// Highlghts the site name in blue
    func setupTitleColors() {
        // find the index where the vertical name goes, so that it won't be confused
        // with any word in the title
        let replacementIndex = NSString(string: TextContent.title).range(of: "%@")

        guard !siteVerticalName.isEmpty, replacementIndex.length > 0 else {
            titleLabel.setText(TextContent.defaultTitle)
            return
        }

        let fullTitle = String(format: TextContent.title, siteVerticalName)
        let attributedTitle = NSMutableAttributedString(string: fullTitle)
        let replacementRange = NSRange(location: replacementIndex.location, length: siteVerticalName.utf16.count)

        attributedTitle.addAttributes([
            .foregroundColor: UIColor.primary,
        ], range: replacementRange)
        titleLabel.attributedText = attributedTitle
    }

    /// sets up the continue button on top of the keyboard
    func setupContinueButton() {
        continueButton.isEnabled = false
        searchBar.inputAccessoryView = continueButtonView
        continueButtonView.frame = Metrics.continueButtonViewFrame(frame.width)
        setContinueButtonConstraints()
    }

    /// sets the default constraints for the continue button
    func setContinueButtonConstraints() {
        continueButtonTopConstraint =
        continueButtonView
            .safeAreaLayoutGuide
            .topAnchor
            .constraint(equalTo: continueButton.topAnchor,
                        constant: -Metrics.continueButtonStandardPadding)

        continueButtonBottomConstraint =
        continueButtonView.safeAreaLayoutGuide
            .bottomAnchor
            .constraint(equalTo: continueButton.bottomAnchor,
                        constant: Metrics.continueButtonStandardPadding)

        continueButtonLeadingConstraint =
        continueButtonView.safeAreaLayoutGuide
            .leadingAnchor
            .constraint(equalTo: continueButton.leadingAnchor,
                        constant: -Metrics.continueButtonStandardPadding)

        continueButtonTrailingConstraint =
        continueButtonView
            .safeAreaLayoutGuide
            .trailingAnchor
            .constraint(equalTo: continueButton.trailingAnchor,
                        constant: Metrics.continueButtonStandardPadding)
    }

    /// Updates the constraints of the Continue button on iPad, so that the button and the search text field are at the same width
    func updateContinueButton() {
        guard UIDevice.isPad(), let windowWidth = UIApplication.shared.mainWindow?.frame.width else {
            return
        }
        continueButtonLeadingConstraint.isActive = false
        continueButtonTrailingConstraint.isActive = false

        let padding = (windowWidth - searchBar.frame.width) / 2 + Metrics.continueButtonAdditionaliPadPadding

        continueButtonLeadingConstraint = continueButtonView.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: continueButton.leadingAnchor, constant: -padding)
        continueButtonTrailingConstraint = continueButtonView.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: padding)
        NSLayoutConstraint.activate([continueButtonLeadingConstraint, continueButtonTrailingConstraint])
    }

    /// activates all constraints
    func activateConstraints() {
        titleLabelView.pinSubviewToSafeArea(titleLabel, insets: Metrics.titlesInsets)
        subtitleLabelView.pinSubviewToSafeArea(subtitleLabel, insets: Metrics.titlesInsets)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor,
                                               constant: Metrics.mainStackViewTopPadding),
            mainStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                   constant: Metrics.mainStackViewSidePadding),
            mainStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                    constant: -Metrics.mainStackViewSidePadding),
            searchBar.heightAnchor.constraint(equalToConstant: Metrics.searchbarHeight),
            continueButtonTopConstraint,
            continueButtonBottomConstraint,
            continueButtonLeadingConstraint,
            continueButtonTrailingConstraint
        ])
    }

    /// hides or shows titles based on the passed boolean parameter
    func hideTitlesIfNeeded() {
        let isAccessibility = traitCollection.verticalSizeClass == .compact ||
        traitCollection.preferredContentSizeCategory.isAccessibilityCategory

        let isVerylarge = [
            UIContentSizeCategory.extraExtraLarge,
            UIContentSizeCategory.extraExtraExtraLarge
        ].contains(traitCollection.preferredContentSizeCategory)

        titleLabelView.isHidden = isAccessibility

        subtitleLabelView.isHidden = isAccessibility || isVerylarge || isIphoneSEorSmaller
    }

    var isIphoneSEorSmaller: Bool {
        UIScreen.main.nativeBounds.height <= Metrics.smallerIphonesNativeBoundsHeight &&
        UIScreen.main.nativeScale <= Metrics.nativeScale
    }
}

// MARK: appearance
private extension SiteNameView {

    enum TextContent {
        static let title = NSLocalizedString("Give your %@ website a name",
                                             comment: "Title of the Site Name screen. Takes the vertical name as a parameter.")
        static let defaultTitle = NSLocalizedString("Give your website a name",
                                                    comment: "Default title of the Site Name screen.")
        static let subtitle = NSLocalizedString("A good name is short and memorable.\nYou can change it later.",
                                                comment: "Subtitle of the Site Name screen.")
        static let continueButtonTitle = NSLocalizedString("Continue",
                                                           comment: "Title of the Continue button in the Site Name screen.")
    }

    enum Metrics {
        // main stack view
        static let mainStackViewVerticalSpacing: CGFloat = 18
        static let mainStackViewTopPadding: CGFloat = 10
        static let mainStackViewSidePadding: CGFloat = 8
        // search bar
        static let searchbarHeight: CGFloat = 64
        // title and subtitle
        static let numberOfLinesInTitle = 3
        static let numberOfLinesInSubtitle = 0
        static let titlesInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let verticalNameDisplayLimit = 32
        static let titleMinimumScaleFactor: CGFloat = 0.75
        //continue button
        static let continueButtonStandardPadding: CGFloat = 16
        static let continueButtonAdditionaliPadPadding: CGFloat = 8
        static let continueButtonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static func continueButtonViewFrame(_ accessoryWidth: CGFloat) -> CGRect {
            CGRect(x: 0, y: 0, width: accessoryWidth, height: 76)
        }
        // native bounds height and scale of iPhone SE 3rd gen and iPhone 8
        static let smallerIphonesNativeBoundsHeight: CGFloat = 1334
        static let nativeScale: CGFloat = 2
    }
}

// MARK: search bar delegate
extension SiteNameView: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // disable the continue button if the text is either empty or contains only spaces, newlines or tabs.
        continueButton.isEnabled = searchText.first(where: { !$0.isWhitespace }) != nil
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        updateContinueButton()
    }
}
