import UIKit

extension NSNotification.Name {
    static let createSite = NSNotification.Name(rawValue: "PSICreateSite")
    static let addSelfHosted = NSNotification.Name(rawValue: "PSIAddSelfHosted")
}

private struct Constants {
    static let welcomeTitleText = NSLocalizedString(
        "Welcome to WordPress",
        comment: "Post Signup Interstitial Title Text"
    )

    static let subTitleText = NSLocalizedString(
        "Whatever you want to create or share, we'll help you do it right here.",
        comment: "Post Signup Interstitial Subtitle Text"
    )

    static let createSiteButtonTitleText = NSLocalizedString(
        "Create a new site",
        comment: "Title for a button that when tapped starts the site creation process"
    )

    static let addSelfHostedButtonTitleText = NSLocalizedString(
        "Add a self-hosted site",
        comment: "Title for a button that when tapped starts the add self-hosted site process"
    )

    static let cancelButtonTitleText = NSLocalizedString(
        "Not right now",
        comment: "Title for a button that when tapped cancels the site creation process"
    )
}

class PostSignUpInterstitialViewController: UIViewController {
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var createSiteButton: UIButton!
    @IBOutlet weak var addSelfHostedButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .listBackground

        configureI18N()
    }

    // MARK: - IBAction's
    @IBAction func createSite(_ sender: Any) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .createSite, object: nil)
        }
    }

    @IBAction func addSelfHosted(_ sender: Any) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .addSelfHosted, object: nil)
        }
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Private
    private func configureI18N() {
        welcomeLabel.text = Constants.welcomeTitleText
        subTitleLabel.text = Constants.subTitleText
        createSiteButton.setTitle(Constants.createSiteButtonTitleText, for: .normal)
        addSelfHostedButton.setTitle(Constants.addSelfHostedButtonTitleText, for: .normal)
        cancelButton.setTitle(Constants.cancelButtonTitleText, for: .normal)
    }
}
