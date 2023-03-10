import UIKit

final class QuickStartPromptViewController: UIViewController {

    // MARK: - IBOutlets

    /// Site info
    @IBOutlet private weak var siteIconView: UIImageView!
    @IBOutlet private weak var siteTitleLabel: UILabel!
    @IBOutlet private weak var siteDescriptionLabel: UILabel!

    /// Prompt info
    @IBOutlet private(set) weak var promptTitleLabel: UILabel!
    @IBOutlet private(set) weak var promptDescriptionLabel: UILabel!

    /// Buttons
    @IBOutlet private(set) weak var showMeAroundButton: FancyButton!
    @IBOutlet private(set) weak var noThanksButton: FancyButton!

    /// Constraints
    @IBOutlet private(set) weak var scrollViewTopVerticalConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scrollViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scrollViewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Properties

    private let blog: Blog
    private let quickStartSettings: QuickStartSettings

    /// Closure to be executed upon dismissal.
    ///
    /// - Parameters:
    ///   - Blog: the blog for which the prompt was dismissed
    ///   - Bool: `true` if Quick Start should start, otherwise `false`
    var onDismiss: ((Blog, Bool) -> Void)?

    // MARK: - Init

    init(blog: Blog, quickStartSettings: QuickStartSettings = QuickStartSettings()) {
        self.blog = blog
        self.quickStartSettings = quickStartSettings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyles()
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .layoutChanged, argument: promptTitleLabel)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupScrollViewMargins()
    }

    // MARK: - Styling

    private func applyStyles() {
        siteTitleLabel.numberOfLines = 0
        siteTitleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        siteTitleLabel.adjustsFontForContentSizeCategory = true
        siteTitleLabel.adjustsFontSizeToFitWidth = true
        siteTitleLabel.textColor = .text

        siteDescriptionLabel.numberOfLines = 0
        siteDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        siteDescriptionLabel.adjustsFontForContentSizeCategory = true
        siteDescriptionLabel.adjustsFontSizeToFitWidth = true
        siteDescriptionLabel.textColor = .textSubtle

        promptTitleLabel.numberOfLines = 0
        promptTitleLabel.font = UIFont.current.prominent(style: .title2, weight: .semibold)
        promptTitleLabel.adjustsFontForContentSizeCategory = true
        promptTitleLabel.adjustsFontSizeToFitWidth = true
        promptTitleLabel.textColor = .text

        promptDescriptionLabel.numberOfLines = 0
        promptDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        promptDescriptionLabel.adjustsFontForContentSizeCategory = true
        promptDescriptionLabel.adjustsFontSizeToFitWidth = true
        promptDescriptionLabel.textColor = .textSubtle

        showMeAroundButton.isPrimary = true
        noThanksButton.isPrimary = false
    }

    // MARK: - Setup

    private func setup() {
        setupScrollViewMargins()
        setupSiteInfoViews()
        setupPromptInfoViews()
        setupButtons()
    }

    private func setupScrollViewMargins() {
        let margin = view.getHorizontalMargin() + Constants.marginPadding
        scrollViewLeadingConstraint.constant = margin
        scrollViewTrailingConstraint.constant = margin
    }

    private func setupSiteInfoViews() {
        siteIconView.downloadSiteIcon(for: blog)

        let displayURL = blog.displayURL as String? ?? ""
        if let name = blog.settings?.name?.nonEmptyString() {
            siteTitleLabel.text = name
            siteDescriptionLabel.text = displayURL
        } else {
            siteTitleLabel.text = displayURL
            siteDescriptionLabel.text = nil
        }
    }

    private func setupPromptInfoViews() {
        promptTitleLabel.text = Strings.promptTitle
        promptDescriptionLabel.text = Strings.promptDescription
    }

    private func setupButtons() {
        showMeAroundButton.setTitle(Strings.showMeAroundButtonTitle, for: .normal)
        noThanksButton.setTitle(Strings.noThanksButtonTitle, for: .normal)
    }

    // MARK: - IBAction

    @IBAction private func showMeAroundButtonTapped(_ sender: Any) {
        onDismiss?(blog, true)
        dismiss(animated: true)

        WPAnalytics.trackQuickStartStat(.quickStartRequestAlertButtonTapped,
                                        properties: ["type": "positive"],
                                        blog: blog)
    }

    @IBAction private func noThanksButtonTapped(_ sender: Any) {
        quickStartSettings.setPromptWasDismissed(true, for: blog)
        onDismiss?(blog, false)
        dismiss(animated: true)

        WPAnalytics.trackQuickStartStat(.quickStartRequestAlertButtonTapped,
                                        properties: ["type": "neutral"],
                                        blog: blog)
    }
}

extension QuickStartPromptViewController {

    private enum Strings {
        static let promptTitle = NSLocalizedString("Want a little help managing this site with the app?", comment: "Title for a prompt asking if users want to try out the quick start checklist.")
        static let promptDescription = NSLocalizedString("Learn the basics with a quick walk through.", comment: "Description for a prompt asking if users want to try out the quick start checklist.")
        static let showMeAroundButtonTitle = NSLocalizedString("Show me around", comment: "Button title. When tapped, the quick start checklist will be shown.")
        static let noThanksButtonTitle = NSLocalizedString("No thanks", comment: "Button title. When tapped, the quick start checklist will not be shown, and the prompt will be dismissed.")
    }

    private enum Constants {
        static let marginPadding = 20.0
    }

}
