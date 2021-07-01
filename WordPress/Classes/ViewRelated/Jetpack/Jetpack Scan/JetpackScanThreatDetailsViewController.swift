import UIKit
import WordPressFlux

protocol JetpackScanThreatDetailsViewControllerDelegate: AnyObject {
    func willFixThreat(_ threat: JetpackScanThreat, controller: JetpackScanThreatDetailsViewController)
    func willIgnoreThreat(_ threat: JetpackScanThreat, controller: JetpackScanThreatDetailsViewController)
}

class JetpackScanThreatDetailsViewController: UIViewController {

    // MARK: - IBOutlets

    /// General info
    @IBOutlet private weak var generalInfoStackView: UIStackView!
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var generalInfoTitleLabel: UILabel!
    @IBOutlet private weak var generalInfoDescriptionLabel: UILabel!

    /// Problem
    @IBOutlet private weak var problemStackView: UIStackView!
    @IBOutlet private weak var problemTitleLabel: UILabel!
    @IBOutlet private weak var problemDescriptionLabel: UILabel!

    /// Technical details
    @IBOutlet private weak var technicalDetailsStackView: UIStackView!
    @IBOutlet private weak var technicalDetailsTitleLabel: UILabel!
    @IBOutlet private weak var technicalDetailsDescriptionLabel: UILabel!
    @IBOutlet private weak var technicalDetailsFileContainerView: UIView!
    @IBOutlet private weak var technicalDetailsFileLabel: UILabel!
    @IBOutlet private weak var technicalDetailsContextLabel: UILabel!

    /// Fix
    @IBOutlet private weak var fixStackView: UIStackView!
    @IBOutlet private weak var fixTitleLabel: UILabel!
    @IBOutlet private weak var fixDescriptionLabel: UILabel!

    /// Buttons
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var fixThreatButton: FancyButton!
    @IBOutlet private weak var ignoreThreatButton: FancyButton!
    @IBOutlet private weak var warningButton: MultilineButton!
    @IBOutlet weak var ignoreActivityIndicatorView: UIActivityIndicatorView!

    // MARK: - Properties

    weak var delegate: JetpackScanThreatDetailsViewControllerDelegate?

    private let blog: Blog
    private let threat: JetpackScanThreat
    private let hasValidCredentials: Bool

    private lazy var viewModel: JetpackScanThreatViewModel = {
        return JetpackScanThreatViewModel(threat: threat, hasValidCredentials: hasValidCredentials)
    }()

    // MARK: - Init

    init(blog: Blog, threat: JetpackScanThreat, hasValidCredentials: Bool = false) {
        self.blog = blog
        self.threat = threat
        self.hasValidCredentials = hasValidCredentials
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.title
        configure(with: viewModel)
    }

    // MARK: - IBActions

    @IBAction private func fixThreatButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: viewModel.fixActionTitle,
                                      message: viewModel.fixDescription,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.delegate?.willFixThreat(self.threat, controller: self)
            self.trackEvent(.jetpackScanThreatFixTapped)
        }))

        present(alert, animated: true)

        trackEvent(.jetpackScanFixThreatDialogOpen)
    }

    @IBAction private func ignoreThreatButtonTapped(_ sender: Any) {
        guard let blogName = blog.settings?.name else {
            return
        }

        let alert = UIAlertController(title: viewModel.ignoreActionTitle,
                                      message: String(format: viewModel.ignoreActionMessage, blogName),
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: { [weak self] _ in
            guard let self = self else {
                return
            }

            self.ignoreThreatButton.isHidden = true
            self.ignoreActivityIndicatorView.startAnimating()

            self.delegate?.willIgnoreThreat(self.threat, controller: self)
            self.trackEvent(.jetpackScanThreatIgnoreTapped)
        }))

        present(alert, animated: true)

        trackEvent(.jetpackScanIgnoreThreatDialogOpen)
    }

    @IBAction func warningButtonTapped(_ sender: Any) {
        guard let siteID = blog.dotComID as? Int,
              let controller = JetpackWebViewControllerFactory.settingsController(siteID: siteID) else {
            displayNotice(title: Strings.jetpackSettingsNotice)
            return
        }

        let navVC = UINavigationController(rootViewController: controller)
        present(navVC, animated: true)
    }

    // MARK: - Private

    private func trackEvent(_ event: WPAnalyticsEvent) {
        WPAnalytics.track(event, properties: ["threat_signature": threat.signature])
    }
}

extension JetpackScanThreatDetailsViewController {

    // MARK: - Configure

    func configure(with viewModel: JetpackScanThreatViewModel) {
        icon.image = viewModel.detailIconImage
        icon.tintColor = viewModel.detailIconImageColor

        generalInfoTitleLabel.text = viewModel.title
        generalInfoDescriptionLabel.text = viewModel.description

        problemTitleLabel.text = viewModel.problemTitle
        problemDescriptionLabel.text = viewModel.problemDescription

        if let attributedFileContext = self.viewModel.attributedFileContext {
            technicalDetailsTitleLabel.text = viewModel.technicalDetailsTitle
            technicalDetailsDescriptionLabel.text = viewModel.technicalDetailsDescription
            technicalDetailsFileLabel.text = viewModel.fileName
            technicalDetailsContextLabel.attributedText = attributedFileContext
            technicalDetailsStackView.isHidden = false
        } else {
            technicalDetailsStackView.isHidden = true
        }

        fixTitleLabel.text = viewModel.fixTitle
        fixDescriptionLabel.text = viewModel.fixDescription

        if let fixActionTitle = viewModel.fixActionTitle {
            fixThreatButton.setTitle(fixActionTitle, for: .normal)
            fixThreatButton.isEnabled = viewModel.fixActionEnabled
            fixThreatButton.isHidden = false
        } else {
            fixThreatButton.isHidden = true
        }

        if let ignoreActionTitle = viewModel.ignoreActionTitle {
            ignoreThreatButton.setTitle(ignoreActionTitle, for: .normal)
            ignoreThreatButton.isHidden = false
        } else {
            ignoreThreatButton.isHidden = true
        }

        if let warningActionTitle = viewModel.warningActionTitle {

            let attributedTitle = WPStyleGuide.Jetpack.highlightString(warningActionTitle.substring,
                                                                       inString: warningActionTitle.string)

            warningButton.setAttributedTitle(attributedTitle, for: .normal)

            warningButton.isHidden = false

        } else {
            warningButton.isHidden = true
        }

        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        view.backgroundColor = .basicBackground
        styleGeneralInfoSection()
        styleProblemSection()
        styleTechnicalDetailsSection()
        styleFixSection()
        styleButtons()
    }

    private func styleGeneralInfoSection() {
        generalInfoTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        generalInfoTitleLabel.textColor = .error
        generalInfoTitleLabel.numberOfLines = 0

        generalInfoDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        generalInfoDescriptionLabel.textColor = .text
        generalInfoDescriptionLabel.numberOfLines = 0
    }

    private func styleProblemSection() {
        problemTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        problemTitleLabel.textColor = .text
        problemTitleLabel.numberOfLines = 0

        problemDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        problemDescriptionLabel.textColor = .text
        problemDescriptionLabel.numberOfLines = 0
    }

    private func styleTechnicalDetailsSection() {
        technicalDetailsTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        technicalDetailsTitleLabel.textColor = .text
        technicalDetailsTitleLabel.numberOfLines = 0

        technicalDetailsFileContainerView.backgroundColor = viewModel.fileNameBackgroundColor

        technicalDetailsFileLabel.font = viewModel.fileNameFont
        technicalDetailsFileLabel.textColor = viewModel.fileNameColor
        technicalDetailsFileLabel.numberOfLines = 0

        technicalDetailsDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        technicalDetailsDescriptionLabel.textColor = .text
        technicalDetailsDescriptionLabel.numberOfLines = 0

        technicalDetailsContextLabel.numberOfLines = 0
    }

    private func styleFixSection() {
        fixTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        fixTitleLabel.textColor = .text
        fixTitleLabel.numberOfLines = 0

        fixDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        fixDescriptionLabel.textColor = .text
        fixDescriptionLabel.numberOfLines = 0
    }

    private func styleButtons() {
        fixThreatButton.isPrimary = true

        ignoreThreatButton.isPrimary = false

        warningButton.setTitleColor(.text, for: .normal)
        warningButton.titleLabel?.lineBreakMode = .byWordWrapping
        warningButton.titleLabel?.numberOfLines = 0
        warningButton.setImage(.gridicon(.plusSmall), for: .normal)
    }
}

extension JetpackScanThreatDetailsViewController {

    private enum Strings {
        static let title = NSLocalizedString("Threat details", comment: "Title for the Jetpack Scan Threat Details screen")
        static let ok = NSLocalizedString("OK", comment: "OK button for alert")
        static let cancel = NSLocalizedString("Cancel", comment: "Cancel button for alert")
        static let jetpackSettingsNotice = NSLocalizedString("Unable to visit Jetpack settings for site", comment: "Message displayed when visiting the Jetpack settings page fails.")
    }
}
