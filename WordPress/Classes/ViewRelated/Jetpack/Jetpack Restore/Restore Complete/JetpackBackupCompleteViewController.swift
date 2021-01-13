import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupCompleteViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Backup", comment: "Title for Jetpack Backup Complete screen")
        view.backgroundColor = .basicBackground
        configureNavigation()
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                           target: self,
                                                           action: #selector(doneTapped))
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true)
    }

}
