import ContactUs
import UIKit

class DemoViewController: UIViewController {

    let controller = ContactSupportFlowController(
        onSupportRequested: {},
        onHelpPageLoaded: { _ in }
    )

    @objc func contactSupport(_ sender: UIControl) {
        controller.present(from: self, completion: .none)
    }

    // MARK: – Boring UIViewController setup logic

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let button = UIButton(frame: .zero)
        view.addSubview(button)

        configureButtonAutolayout(button)

        button.setTitle("Contact Support", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)

        button.addTarget(self, action: #selector(contactSupport), for: .primaryActionTriggered)
    }

    func configureButtonAutolayout(_ button: UIButton) {
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints(
            [
                .init(
                    item: button,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .centerX,
                    multiplier: 1,
                    constant: 0
                ),
                .init(
                    item: button,
                    attribute: .centerY,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .centerY,
                    multiplier: 1,
                    constant: 0
                ),
                .init(
                    item: button,
                    attribute: .width,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .width,
                    multiplier: 1,
                    constant: 0
                )
            ]
        )
    }
}
