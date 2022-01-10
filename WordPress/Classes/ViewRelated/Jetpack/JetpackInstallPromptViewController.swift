import UIKit
import WordPressAuthenticator

class JetpackInstallPromptViewController: UIViewController {
    var starFieldView: StarFieldView = {
        let config = StarFieldViewConfig(particleImage: JetpackPromptStyles.Stars.particleImage,
                                         starColors: JetpackPromptStyles.Stars.colors)
        let view = StarFieldView(with: config)
        view.layer.masksToBounds = true
        return view
    }()

    var gradientLayer: CALayer = {
        let gradientLayer = CAGradientLayer()

        // Start color is the background color with no alpha because if we use clear it will fade to black
        // instead of just disappearing
        let startColor = JetpackPromptStyles.backgroundColor.withAlphaComponent(0)
        let endColor = JetpackPromptStyles.backgroundColor

        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.locations = [0.0, 0.9]

        return gradientLayer
    }()

    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var installButton: FancyButton!
    @IBOutlet weak var noThanksButton: FancyButton!
    @IBOutlet weak var learnMoreButton: FancyButton!
    @IBOutlet weak var buttonsStackView: UIStackView!

    // MARK: - Properties

    private let blog: Blog

    enum DismissAction {
        case install
        case noThanks
    }

    /// Closure to be executed upon dismissal.
    ///
    var dismiss: ((_ action: DismissAction) -> Void)?

    // MARK: - Init

    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true

        view.backgroundColor = JetpackPromptStyles.backgroundColor
        backgroundView.backgroundColor = JetpackPromptStyles.backgroundColor
        backgroundView.addSubview(starFieldView)
        backgroundView.layer.addSublayer(gradientLayer)

        titleLabel.font = JetpackPromptStyles.Title.font
        titleLabel.textColor = JetpackPromptStyles.Title.textColor

        installButton.isPrimary = true
        configure(button: installButton, style: JetpackPromptStyles.installButtonStyle)
        configure(button: noThanksButton, style: JetpackPromptStyles.noThanksButtonStyle)
        configure(button: learnMoreButton, style: JetpackPromptStyles.learnMoreButtonStyle)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        starFieldView.frame = view.bounds
        gradientLayer.frame = view.bounds
    }
    // MARK: - Actions

    @IBAction func installTapped(_ sender: Any) {
        dismiss?(.install)
        dismiss(animated: true)
    }

    @IBAction func noThanksTapped(_ sender: Any) {
        dismiss?(.noThanks)
        dismiss(animated: true)
    }

    @IBAction func learnMoreButtonTapped(_ sender: Any) {
        guard let url = URL(string: "https://jetpack.com/features/") else {
            return
        }

        let controller = WebViewControllerFactory.controller(url: url, source: "jetpack_prompt")
        let navController = UINavigationController(rootViewController: controller)
        self.present(navController, animated: true)
    }

    private func configure(button: FancyButton, style: NUXButtonStyle) {
        guard button.isPrimary else {
            button.secondaryNormalBackgroundColor = style.normal.backgroundColor
            button.secondaryNormalBorderColor = style.normal.borderColor
            button.secondaryTitleColor = style.normal.titleColor
            button.secondaryHighlightBackgroundColor = style.highlighted.backgroundColor
            button.secondaryHighlightBorderColor = style.highlighted.borderColor
            return
        }

        button.primaryNormalBackgroundColor = style.normal.backgroundColor
        button.primaryNormalBorderColor = style.normal.borderColor
        button.primaryTitleColor = style.normal.titleColor
        button.primaryHighlightBackgroundColor = style.highlighted.backgroundColor
        button.primaryHighlightBorderColor = style.highlighted.borderColor
    }
}

// MARK: - Notifications
extension NSNotification.Name {
    static let installJetpack = NSNotification.Name(rawValue: "JetpackInstall")
}

// MARK: - Styles
struct JetpackPromptStyles {
    static let backgroundColor = UIColor(red: 0.00, green: 0.11, blue: 0.18, alpha: 1.00)

    struct Title {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .semibold)
        static let textColor: UIColor = .white
    }

    struct Stars {
        static let particleImage = UIImage(named: "jetpack-circle-particle")

        static let colors = [
            UIColor(red: 0.05, green: 0.27, blue: 0.44, alpha: 0.5),
            UIColor(red: 0.64, green: 0.68, blue: 0.71, alpha: 0.5),
            UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 0.5)
        ]
    }
    static let installButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: .white,
                                                                 borderColor: .white,
                                                                 titleColor: Self.backgroundColor),

                                                   highlighted: .init(backgroundColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90),
                                                                      borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90),
                                                                      titleColor: Self.backgroundColor),

                                                   disabled: .init(backgroundColor: .white,
                                                                   borderColor: .white,
                                                                   titleColor: Self.backgroundColor))

    static let noThanksButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: Self.backgroundColor,
                                                                   borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.40),
                                                                   titleColor: .white),

                                                     highlighted: .init(backgroundColor: Self.backgroundColor,
                                                                        borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.20),
                                                                        titleColor: UIColor.white.withAlphaComponent(0.7)),

                                                     disabled: .init(backgroundColor: .white,
                                                                     borderColor: .white,
                                                                     titleColor: Self.backgroundColor))

    static let learnMoreButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: Self.backgroundColor,
                                                                   borderColor: Self.backgroundColor,
                                                                   titleColor: .white),

                                                     highlighted: .init(backgroundColor: Self.backgroundColor,
                                                                        borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.20),
                                                                        titleColor: UIColor.white.withAlphaComponent(0.7)),

                                                     disabled: .init(backgroundColor: .white,
                                                                     borderColor: .white,
                                                                     titleColor: Self.backgroundColor))

}
