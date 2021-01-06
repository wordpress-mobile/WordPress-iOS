import Foundation
import CocoaLumberjack
import WordPressShared

class JetpackRestoreProgressViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Restore", comment: "Title for Jetpack Restore Progress screen")
        configureNavigation()
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                           target: self,
                                                           action: #selector(doneTapped))
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true)
    }
}
