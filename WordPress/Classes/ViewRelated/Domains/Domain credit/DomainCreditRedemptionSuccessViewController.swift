import UIKit
import WordPressUI

protocol DomainCreditRedemptionSuccessViewControllerDelegate: AnyObject {
    func continueButtonPressed(domain: String)
}

/// Displays messaging after user successfully redeems domain credit.
class DomainCreditRedemptionSuccessViewController: UIViewController {

    private let domain: String

    private weak var delegate: DomainCreditRedemptionSuccessViewControllerDelegate?

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
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textAlignment = .center
        title.font = WPStyleGuide.serifFontForTextStyle(.largeTitle)
        title.textColor = .white
        title.text = TextContent.title
        title.adjustsFontForContentSizeCategory = true
        return title
    }()

    private lazy var subtitleLabel: UILabel = {
        let subtitle = UILabel()
        subtitle.numberOfLines = 0
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.textAlignment = .center
        subtitle.textColor = .white
        subtitle.adjustsFontForContentSizeCategory = true

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
        button.isPrimary = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(TextContent.doneButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.isPrimary = false
        button.accessibilityIdentifier = Accessibility.doneButtonIdentifier
        button.accessibilityHint = Accessibility.doneButtonHint
        button.secondaryNormalBackgroundColor = UIColor(light: .white, dark: .muriel(name: .blue, .shade40))
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

    private lazy var divider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        return view
    }()


    // MARK: - View lifecycle

    init(domain: String, delegate: DomainCreditRedemptionSuccessViewControllerDelegate) {
        self.domain = domain
        self.delegate = delegate
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

        self.view.backgroundColor = UIColor(light: .primary, dark: .secondarySystemBackground)

        navigationController?.setNavigationBarHidden(true, animated: false)

        setupViewHierarchy()
        configureConstraints()
    }

    private func setupViewHierarchy() {
        stackView.addArrangedSubviews([illustration, titleLabel, subtitleLabel])
        stackViewContainer.addSubview(stackView)
        scrollView.addSubview(stackViewContainer)
        view.addSubview(scrollView)
        view.addSubview(doneButtonContainer)
        view.addSubview(divider)
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

            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: doneButtonContainer.topAnchor),
            divider.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth)
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
        String(format: TextContent.domainDetailsString, domain)
    }

    // MARK: - Actions

    @objc func doneButtonTapped() {
        delegate?.continueButtonPressed(domain: domain)
    }

    // MARK: - Constants

    private let subtitleFont = UIFont.preferredFont(forTextStyle: .title3)

    private enum TextContent {
        static let title = NSLocalizedString("Congratulations on your purchase!", comment: "Title of domain name purchase success screen")
        static let domainDetailsString = NSLocalizedString("Your new domain %@ is being set up. It may take up to 30 minutes for your domain to start working.",
                                                           comment: "Details about recently acquired domain on domain credit redemption success screen")
        static let doneButtonTitle = NSLocalizedString("Done",
                                                       comment: "Done button title")
    }

    private enum Metrics {
        static let stackViewSpacing: CGFloat = 16.0
        static let buttonControllerMinHeight: CGFloat = 84.0
        static let edgePadding: CGFloat = 20.0
        static let doneButtonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    private enum Accessibility {
        static let doneButtonIdentifier = "DomainsSuccessDoneButton"
        static let doneButtonHint = NSLocalizedString("Dismiss screen", comment: "Accessibility hint for a done button that dismisses the current modal screen")
    }
}
