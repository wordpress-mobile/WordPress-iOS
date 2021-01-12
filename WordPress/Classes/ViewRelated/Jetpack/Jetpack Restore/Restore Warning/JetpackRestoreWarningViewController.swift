import Foundation
import CocoaLumberjack
import WordPressShared

class JetpackRestoreWarningViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Warning", comment: "Title for Jetpack Restore Warning screen")
        configureWarningView()
    }

    private func configureWarningView() {
        let warningView = RestoreWarningView.loadFromNib()

        warningView.confirmHandler = { [weak self] in
//            let statusVC = JetpackRestoreStatusViewController()
//            self?.navigationController?.pushViewController(statusVC, animated: true)
        }

        warningView.cancelHandler = { [weak self] in
            self?.dismiss(animated: true)
        }

        warningView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningView)
        view.pinSubviewToAllEdges(warningView)
    }

}
