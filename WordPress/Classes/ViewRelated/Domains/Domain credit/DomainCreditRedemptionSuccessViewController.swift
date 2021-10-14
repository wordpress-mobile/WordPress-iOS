import UIKit
import WordPressAuthenticator

protocol DomainCreditRedemptionSuccessViewControllerDelegate: AnyObject {
    func continueButtonPressed(domain: String)
}

/// Displays messaging after user successfully redeems domain credit.
class DomainCreditRedemptionSuccessViewController: UIViewController {
    
    private let domain: String
    private var illustration: UIImageView?

    private weak var delegate: DomainCreditRedemptionSuccessViewControllerDelegate?

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
        illustration?.isHidden = traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) || traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .primary

        navigationController?.setNavigationBarHidden(true, animated: false)

        // Stack View

        let stackViewContainer = UIView()
        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
        stackViewContainer.setContentHuggingPriority(.defaultLow, for: .vertical)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.stackViewSpacing
        stackView.alignment = .fill

        // Image

        let illustration = UIImageView(image: UIImage(named: "domains-success"))
        illustration.contentMode = .scaleAspectFit
        self.illustration = illustration

        // Labels

        let title = UILabel()
        title.numberOfLines = 0
        title.textAlignment = .center
        title.font = WPStyleGuide.serifFontForTextStyle(.largeTitle)
        title.textColor = .textInverted
        title.text = TextContent.title

        let subtitle = UILabel()
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        subtitle.textColor = .textInverted
        self.subtitle = subtitle

        let subtitleText = makeDomainDetailsString(domain: domain)
        subtitle.attributedText = applyDomainStyle(to: subtitleText, domain: domain)

        stackView.addArrangedSubviews([illustration, title, subtitle])

        // Buttons

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonViewController.move(to: self, into: buttonContainer)
        buttonContainer.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // Constraints

        stackViewContainer.addSubview(stackView)
        view.addSubview(stackViewContainer)
        view.addSubview(buttonContainer)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: stackViewContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackViewContainer.trailingAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackViewContainer.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackViewContainer.bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackViewContainer.centerYAnchor),

            stackViewContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: Metrics.edgePadding),
            stackViewContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -Metrics.edgePadding),
            stackViewContainer.topAnchor.constraint(equalTo: view.safeTopAnchor),
            stackViewContainer.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),

            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            buttonContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.buttonControllerMinHeight)
        ])
    }

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

    private lazy var buttonViewController: NUXButtonViewController = {
        let buttonViewController = NUXButtonViewController.instance()
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(
            primary: "Done"
        )

        let normalStyle = NUXButtonStyle.ButtonStyle(backgroundColor: .basicBackground,
                                                     borderColor: .basicBackground,
                                                     titleColor: .text)

        let dimmedStyle = NUXButtonStyle.ButtonStyle(backgroundColor: .basicBackground.withAlphaComponent(0.7),
                                                     borderColor: .basicBackground.withAlphaComponent(0.7),
                                                     titleColor: .text)

        buttonViewController.bottomButtonStyle = NUXButtonStyle(normal: normalStyle,
                                                                highlighted: dimmedStyle,
                                                                disabled: dimmedStyle)

        return buttonViewController
    }()

// MARK: - Constants

    private let subtitleFont = UIFont.preferredFont(forTextStyle: .title3)

    private enum TextContent {
        static let title = NSLocalizedString("Congratulations on your purchase!", comment: "Title of domain name purchase success screen")
        static let domainDetailsString = NSLocalizedString("Your new domain %@ is being set up. It may take up to 30 minutes for your domain to start working.",
                                                           comment: "Details about recently acquired domain on domain credit redemption success screen")
    }
    private enum Metrics {
        static let stackViewSpacing: CGFloat = 16.0
        static let buttonControllerMinHeight: CGFloat = 84.0
        static let edgePadding: CGFloat = 20.0
    }
}

extension DomainCreditRedemptionSuccessViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        delegate?.continueButtonPressed(domain: domain)
    }
}
