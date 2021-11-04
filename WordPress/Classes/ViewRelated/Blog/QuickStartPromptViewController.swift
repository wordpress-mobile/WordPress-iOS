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

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: ((Blog) -> Void)?

    // MARK: - Init

    init(blog: Blog) {
        self.blog = blog
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
        dismissPrompt { [weak self] in

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.quickStartDelay) {
                guard let self = self else {
                    return
                }
                QuickStartTourGuide.shared.setup(for: self.blog)
            }
        }
    }

    @IBAction private func noThanksButtonTapped(_ sender: Any) {
        UserDefaults.standard.setQuickStartWasDismissed(true, for: blog)
        dismissPrompt()
    }

    private func dismissPrompt(completion: (() -> Void)? = nil) {
        onDismiss?(blog)
        navigationController?.dismiss(animated: true, completion: completion)
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
        static let quickStartDelay: DispatchTimeInterval = DispatchTimeInterval.milliseconds(1000)
    }
}

extension UserDefaults {

    func quickStartWasDismissed(for blog: Blog) -> Bool {
        guard let key = quickStartWasDismissedKey(for: blog) else {
            return false
        }
        return bool(forKey: key)
    }

    func setQuickStartWasDismissed(_ value: Bool, for blog: Blog) {
        guard let key = quickStartWasDismissedKey(for: blog) else {
            return
        }
        set(value, forKey: key)
    }

    private func quickStartWasDismissedKey(for blog: Blog) -> String? {
        guard let siteID = blog.dotComID?.intValue else {
            return nil
        }
        return "QuickStartWasDismissed-\(siteID)"
    }
}
