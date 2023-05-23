import UIKit
import WordPressUI

/// Displays messaging after user successfully redeems domain credit.
class DomainCreditRedemptionSuccessViewController: UIViewController {

    private let domain: String

    private var continueButtonPressed: (String) -> Void

    // MARK: - Views

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.setContentHuggingPriority(.defaultLow, for: .vertical)
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.stackViewSpacing
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var stackViewContainer: UIView = {
        let stackViewContainer = UIView()
        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
        stackViewContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        return stackViewContainer
    }()

    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        title.adjustsFontForContentSizeCategory = true
        title.adjustsFontSizeToFitWidth = true
        title.numberOfLines = 0
        title.textColor = .text
        title.text = TextContent.titleString
        return title
    }()

    private lazy var subtitleLabel: UILabel = {
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.numberOfLines = 0
        subtitle.textColor = .text

        let subtitleText = makeDomainDetailsString(domain: domain)
        subtitle.attributedText = applyDomainStyle(to: subtitleText, domain: domain)

        return subtitle
    }()

    private lazy var illustration: UIImageView = {
        let illustration = UIImageView(image: UIImage(named: "domains-success"))
        illustration.contentMode = .scaleAspectFit
        return illustration
    }()

    private lazy var doneButton: FancyButton = {
        let button = FancyButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(TextContent.doneButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.isPrimary = true
        button.primaryNormalBackgroundColor = .jetpackGreen
        button.primaryHighlightBackgroundColor = .muriel(color: .jetpackGreen, .shade80)
        button.accessibilityIdentifier = Accessibility.doneButtonIdentifier
        button.accessibilityHint = Accessibility.doneButtonHint
        return button
    }()

    private lazy var doneButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)
        view.pinSubviewToAllEdges(doneButton, insets: Metrics.doneButtonInsets)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }()

    private lazy var informationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Metrics.stackViewSpacing
        stackView.alignment = .fill
        stackView.backgroundColor = UIColor.secondarySystemBackground
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = Metrics.informationViewMargins
        stackView.layer.cornerRadius = 8

        let infoIconImage = UIImage(systemName: "info.circle")?.withTintColor(.textSubtle, renderingMode: .alwaysOriginal)
        let infoIconImageView = UIImageView(image: infoIconImage)
        infoIconImageView.contentMode = .scaleAspectFit
        infoIconImageView.frame = CGRect(origin: .zero, size: Metrics.iconImageSize)

        let informationLabel = UILabel()
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        informationLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        informationLabel.adjustsFontForContentSizeCategory = true
        informationLabel.adjustsFontSizeToFitWidth = true
        informationLabel.numberOfLines = 0
        informationLabel.textColor = .textSubtle
        informationLabel.text = TextContent.informationString

        stackView.addArrangedSubviews([infoIconImageView, informationLabel])

        return stackView
    }()

    // MARK: - View lifecycle

    init(domain: String, continueButtonPressed: @escaping (String) -> Void) {
        self.domain = domain
        self.continueButtonPressed = continueButtonPressed
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Hide the illustration if we only have compact height, or if the user has
        // dynamic content set to accessibility sizes.
        illustration.isHidden = traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) || traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupViewHierarchy()
        configureConstraints()
    }

    private func setupViewHierarchy() {
        stackView.addArrangedSubviews([illustration, titleLabel, subtitleLabel, informationStackView])
        stackView.setCustomSpacing(Metrics.stackViewSpacing * 2, after: illustration)
        stackView.setCustomSpacing(Metrics.stackViewSpacing * 2, after: subtitleLabel)
        stackViewContainer.addSubview(stackView)
        scrollView.addSubview(stackViewContainer)
        view.addSubview(scrollView)
        view.addSubview(doneButtonContainer)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: stackViewContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackViewContainer.trailingAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackViewContainer.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackViewContainer.bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackViewContainer.centerYAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: Metrics.edgePadding),
            scrollView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -Metrics.edgePadding),
            scrollView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            scrollView.bottomAnchor.constraint(equalTo: doneButtonContainer.topAnchor),

            stackViewContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackViewContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackViewContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: Metrics.edgePadding),
            stackViewContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -Metrics.edgePadding),
            stackViewContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackViewContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackViewContainer.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),

            doneButtonContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            doneButtonContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            doneButtonContainer.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            doneButtonContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.buttonControllerMinHeight),
        ])
    }

    // MARK: - Text helpers

    private func applyDomainStyle(to string: String, domain: String) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: string, attributes: [.font: subtitleFont])
        let newAttributedString = NSMutableAttributedString(attributedString: attributedString)

        let range = (newAttributedString.string as NSString).localizedStandardRange(of: domain)
        guard range.location != NSNotFound else {
            return nil
        }
        let font = subtitleFont.bold()
        newAttributedString.setAttributes([.font: font],
                                          range: range)
        return newAttributedString
    }

    private func makeDomainDetailsString(domain: String) -> String {
        String(format: TextContent.descriptionString, domain)
    }

    // MARK: - Actions

    @objc func doneButtonTapped() {
        continueButtonPressed(domain)
    }

    // MARK: - Constants

    private let subtitleFont = UIFont.preferredFont(forTextStyle: .title3)

    private enum TextContent {
        static let titleString = NSLocalizedString("domainPurchase.success.title", value: "All ready to go!", comment: "Title of domain name purchase success screen")
        static let descriptionString = NSLocalizedString("domainPurchase.success.description", value: "Your new domain %1$@ is being set up.", comment: "Description of the recently acquired domain.")
        static let informationString = NSLocalizedString("domainPurchase.success.information", value: "It may take up to 30 minutes for your domain to start working properly", comment: "Explanation of the time it takes for domain to start working after the purchase")
        static let doneButtonTitle = NSLocalizedString("Done",
                                                       comment: "Done button title")
    }

    private enum Metrics {
        static let stackViewSpacing: CGFloat = 16.0
        static let buttonControllerMinHeight: CGFloat = 84.0
        static let edgePadding: CGFloat = 20.0
        static let doneButtonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let informationViewMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let iconImageSize = CGSize(width: 24, height: 24)
    }

    private enum Accessibility {
        static let doneButtonIdentifier = "DomainsSuccessDoneButton"
        static let doneButtonHint = NSLocalizedString("Dismiss screen", comment: "Accessibility hint for a done button that dismisses the current modal screen")
    }
}
