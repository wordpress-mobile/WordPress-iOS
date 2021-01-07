import Foundation
import CocoaLumberjack
import WordPressShared

class JetpackRestoreStatusViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Restore", comment: "Title for Jetpack Restore Status screen")
        configureNavigation()
        configureRestoreStatusView()
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                           target: self,
                                                           action: #selector(doneTapped))
    }

    private func configureRestoreStatusView() {
        let statusView = RestoreStatusView.loadFromNib()

        statusView.notifyMeHandler = { [weak self] in
            self?.dismiss(animated: true)
        }

        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)
        view.pinSubviewToAllEdges(statusView)
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true)
    }
}
