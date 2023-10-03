import UIKit

final class PlanWizardContent: WebKitViewController {
    init() {
        let configuration = WebViewControllerConfiguration(url: nil)
        super.init(configuration: configuration)
    }

    // MARK: - Required Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
