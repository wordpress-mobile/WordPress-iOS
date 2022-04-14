import UIKit

class OnboardingEnableNotificationsViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var detailView: UIView!

    var promptSelection: OnboardingOption?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        titleLabel.textColor = .text

        subTitleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .regular)
        subTitleLabel.textColor = .text

        let option = promptSelection ?? .notifications

        let text: String
        let detail: UIView

        switch option {
        case .stats:
            text = "Know when your traffic spikes, or when your site passes a milestone."
            detail = UIView.embedSwiftUIView(UnifiedPrologueStatsContentView())

        case .writing:
            text = "Stay in touch with your audience with like and comment notifications."
            detail = UIView.embedSwiftUIView(UnifiedPrologueNotificationsContentView())

        case .notifications:
            text = "Tap the Allow button to enable notifications."
            detail = UIView.embedSwiftUIView(UnifiedPrologueNotificationsContentView())

        case .reader:
            text = "Know when your favorite authors post new content."
            detail = UIView.embedSwiftUIView(UnifiedPrologueReaderContentView())

        case .other:
            text = "Tap the Allow button to enable notifications."
            detail = UIView.embedSwiftUIView(UnifiedPrologueNotificationsContentView())
        }

        subTitleLabel.text = text

        detail.frame.size.width = detailView.frame.width
        detailView.addSubview(detail)

        detail.pinSubviewToAllEdges(detailView)

        if option == .notifications {
            
        }
    }

    private func showPrompt() {
        InteractiveNotificationsManager.shared.requestAuthorization { authorized in
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }
    }

    @IBAction func enableButtonTapped(_ sender: Any) {
        showPrompt()
    }

    @IBAction func skipButtonTappe(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    private func configure(button: UIButton) {
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.headline)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.textAlignment = .left
        button.titleEdgeInsets.left = 10
    }
}
