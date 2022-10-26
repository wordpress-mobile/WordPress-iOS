import UIKit

class JetpackFullscreenOverlayViewController: UIViewController {

    // MARK: Variables

    private let config: JetpackFullscreenOverlayConfig

    // MARK: Lazy Views

    private lazy var closeButtonItem: UIBarButtonItem = {
        let closeButton = UIButton()

        let configuration = UIImage.SymbolConfiguration(pointSize: Constants.closeButtonSymbolSize, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.backgroundColor = .quaternarySystemFill

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Constants.closeButtonRadius),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])
        closeButton.layer.cornerRadius = Constants.closeButtonRadius * 0.5

        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)

        return UIBarButtonItem(customView: closeButton)
    }()

    // MARK: Outlets

    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var footnoteLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!

    // MARK: Initializers

    init(with config: JetpackFullscreenOverlayConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        applyStyles()
        setupContent()
        setupColors()
        setupFonts()
    }

    // MARK: Helpers

    private func configureNavigationBar() {
        addCloseButtonIfNeeded()

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }
    }

    private func addCloseButtonIfNeeded() {
        guard config.shouldShowCloseButton else {
            return
        }

        navigationItem.rightBarButtonItem = closeButtonItem
    }

    private func applyStyles() {
        iconImageView.clipsToBounds = false
    }

    private func setupContent() {
        iconImageView.image = config.icon
        titleLabel.text = config.title
        subtitleLabel.text = config.subtitle
        footnoteLabel.text = config.footnote
        switchButton.setTitle(config.switchButtonText, for: .normal)
        continueButton.setTitle(config.continueButtonText, for: .normal)
        footnoteLabel.isHidden = config.footnoteIsHidden
        learnMoreButton.isHidden = config.learnMoreButtonIsHidden
        continueButton.isHidden = config.continueButtonIsHidden
    }

    private func setupColors() {

    }

    private func setupFonts() {

    }

    // MARK: Actions

    @objc private func closeButtonPressed(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Constants

private extension JetpackFullscreenOverlayViewController {
    enum Strings {
    }

    enum Constants {
        static let closeButtonRadius: CGFloat = 30
        static let closeButtonSymbolSize: CGFloat = 16
    }
}
