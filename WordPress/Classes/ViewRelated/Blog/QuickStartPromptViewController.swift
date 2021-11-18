import UIKit

final class QuickStartPromptViewController: UIViewController {

    // MARK: - IBOutlets

    /// Site info
    @IBOutlet private weak var siteIconView: UIImageView!
    @IBOutlet private weak var siteTitleLabel: UILabel!
    @IBOutlet private weak var siteDescriptionLabel: UILabel!

    /// Prompt info
    @IBOutlet private weak var promptTitleLabel: UILabel!
    @IBOutlet private weak var promptDescriptionLabel: UILabel!

    /// Buttons
    @IBOutlet private weak var showMeAroundButton: FancyButton!
    @IBOutlet private weak var noThanksButton: FancyButton!

    // MARK: - Properties

    private let blog: Blog
    private let quickStartSettings: QuickStartSettings

    /// Closure to be executed upon dismissing the Login Epilogue.
    ///
    var onDismissEpilogue: (() -> Void)?

    // MARK: - Init

    init(blog: Blog, quickStartSettings: QuickStartSettings? = nil) {
        self.blog = blog
        self.quickStartSettings = quickStartSettings ?? QuickStartSettings()
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

    // MARK: - Styling

    private func applyStyles() {
        siteTitleLabel.numberOfLines = 0
        siteTitleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        siteTitleLabel.textColor = .text

        siteDescriptionLabel.numberOfLines = 0
        siteDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        siteDescriptionLabel.textColor = .textSubtle

        promptTitleLabel.numberOfLines = 0
        promptTitleLabel.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .medium)
        promptTitleLabel.textColor = .text

        promptDescriptionLabel.numberOfLines = 0
        promptDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        promptDescriptionLabel.textColor = .textSubtle

        showMeAroundButton.isPrimary = true
        noThanksButton.isPrimary = false
    }

    // MARK: - Setup

    private func setup() {
        setupSiteInfoViews()
        setupPromptInfoViews()
        setupButtons()
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
        if let onDismissEpilogue = onDismissEpilogue {
            onDismissEpilogue()

            // Show the My Site screen for the specified blog
            WordPressAppDelegate.shared?.windowManager.dismissFullscreenSignIn(blogToShow: blog, completion: {
                // After a short delay, trigger the Quick Start tour
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.quickStartDelay) {
                    QuickStartTourGuide.shared.setup(for: self.blog)
                }
            })

            return
        }

        dismiss(animated: true)
        QuickStartTourGuide.shared.setup(for: blog)
    }

    @IBAction private func noThanksButtonTapped(_ sender: Any) {
        quickStartSettings.setPromptWasDismissed(true, for: blog)

        if let onDismissEpilogue = onDismissEpilogue {
            onDismissEpilogue()
            WordPressAppDelegate.shared?.windowManager.dismissFullscreenSignIn(blogToShow: blog)
            return
        }

        dismiss(animated: true)
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
        static let quickStartDelay: DispatchTimeInterval = .milliseconds(500)
    }
}
