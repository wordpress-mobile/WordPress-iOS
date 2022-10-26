import UIKit

class JetpackFullscreenOverlayViewController: UIViewController {

    // MARK: Variables

    private let config: JetpackFullscreenOverlayConfig

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

        applyStyles()
        setupContent()
    }

    // MARK: Helpers

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
}
