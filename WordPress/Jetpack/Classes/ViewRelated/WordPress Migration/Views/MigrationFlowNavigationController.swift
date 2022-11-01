import UIKit

final class MigrationFlowNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
    }

    private func setupNavigationBar() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        self.navigationBar.standardAppearance = standardAppearance
        self.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        self.navigationBar.compactAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            self.navigationBar.compactScrollEdgeAppearance = scrollEdgeAppearance
        }
        self.navigationBar.isTranslucent = true
    }
}
