import UIKit
import WordPressUI
import WordPressShared

class OnboardingQuestionsPromptViewController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var statsButton: UIButton!
    @IBOutlet weak var postsButton: UIButton!
    @IBOutlet weak var notificationsButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var notSureButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    let coordinator: OnboardingQuestionsCoordinator

    init(with coordinator: OnboardingQuestionsCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required convenience init?(coder: NSCoder) {
        self.init(with: OnboardingQuestionsCoordinator())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true
        navigationController?.delegate = self

        applyStyles()
        updateButtonTitles()

        coordinator.questionsDisplayed()
    }

    // MARK: - View Methods
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        configureButtons()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return [.portrait, .portraitUpsideDown]
    }
}

// MARK: - IBAction's
extension OnboardingQuestionsPromptViewController {
    @IBAction func didTapStats(_ sender: Any) {
        coordinator.didSelect(option: .stats)
    }

    @IBAction func didTapWriting(_ sender: Any) {
        coordinator.didSelect(option: .writing)
    }

    @IBAction func didTapNotifications(_ sender: Any) {
        coordinator.didSelect(option: .notifications)
    }

    @IBAction func didTapReader(_ sender: Any) {
        coordinator.didSelect(option: .reader)
    }

    @IBAction func didTapNotSure(_ sender: Any) {
        coordinator.didSelect(option: .showMeAround)
    }

    @IBAction func skip(_ sender: Any) {
        coordinator.didSelect(option: .skip)
    }
}

// MARK: - Private Helpers
private extension OnboardingQuestionsPromptViewController {
    private func applyStyles() {
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        titleLabel.textColor = .text

        stackView.setCustomSpacing(32, after: titleLabel)
    }

    private func updateButtonTitles() {
        titleLabel.text = Strings.title

        statsButton.setTitle(Strings.stats, for: .normal)
        statsButton.setImage("📊".image(), for: .normal)

        postsButton.setTitle(Strings.writing, for: .normal)
        postsButton.setImage("✍️".image(), for: .normal)

        notificationsButton.setTitle(Strings.notifications, for: .normal)
        notificationsButton.setImage("🔔".image(), for: .normal)

        readButton.setTitle(Strings.reader, for: .normal)
        readButton.setImage("📚".image(), for: .normal)

        notSureButton.setTitle(Strings.notSure, for: .normal)
        notSureButton.setImage("🤔".image(), for: .normal)

        skipButton.setTitle(Strings.skip, for: .normal)
    }

    private func configureButtons() {
        [statsButton, postsButton, notificationsButton, readButton, notSureButton].forEach {
            style(button: $0)
        }
    }

    private func style(button: UIButton) {
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.headline)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.textAlignment = .natural
        button.titleEdgeInsets.left = 10
        button.imageView?.contentMode = .scaleAspectFit
        button.flipInsetsForRightToLeftLayoutDirection()
    }
}

// MARK: - UINavigation Controller Delegate
extension OnboardingQuestionsPromptViewController: UINavigationControllerDelegate {
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return supportedInterfaceOrientations
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        return .portrait
    }
}

// MARK: - CGSize Helper Extension
private extension CGSize {

    /// Get the center point of the size in the given rect
    /// - Parameter rect: The rect to center the size in
    /// - Returns: The center point
    func centered(in rect: CGRect) -> CGPoint {
        let x = rect.midX - (self.width * 0.5)
        let y = rect.midY - (self.height * 0.5)

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Emoji Drawing Helper Extension
private extension String {
    func image() -> UIImage {
        let size = Constants.iconSize
        let imageSize = CGSize(width: size, height: size)
        let rect = CGRect(origin: .zero, size: imageSize)

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)

        UIColor.clear.set()
        UIRectFill(rect)

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: size)]

        let string = self as NSString
        let drawingSize = string.size(withAttributes: attributes)
        string.draw(at: drawingSize.centered(in: rect), withAttributes: attributes)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image?.withRenderingMode(.alwaysOriginal) ?? UIImage()
    }
}

// MARK: - Helper Structs
private struct Strings {
    static let title = NSLocalizedString("What would you like to focus on first?", comment: "Title of the view asking the user what they'd like to focus on")
    static let stats = NSLocalizedString("Checking stats", comment: "Title of button that asks the users if they'd like to focus on checking their sites stats")
    static let writing = NSLocalizedString("Writing blog posts", comment: "Title of button that asks the users if they'd like to focus on checking their sites stats")
    static let notifications = NSLocalizedString("Staying up to date with notifications", comment: "Title of button that asks the users if they'd like to focus on checking their sites stats")
    static let reader = NSLocalizedString("Reading posts from other sites", comment: "Title of button that asks the users if they'd like to focus on checking their sites stats")
    static let notSure = NSLocalizedString("Not sure, show me around", comment: "Button that allows users unsure of what selection they'd like ")
    static let skip = NSLocalizedString("Skip", comment: "Button that allows the user to skip the prompt and be brought to the app")
}

private struct Constants {
    static let iconSize = 24.0
}
