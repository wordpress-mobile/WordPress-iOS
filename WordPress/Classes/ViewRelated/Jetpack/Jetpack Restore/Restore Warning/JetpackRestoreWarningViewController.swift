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
        warningView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningView)
        view.pinSubviewToAllEdges(warningView)
    }

}
