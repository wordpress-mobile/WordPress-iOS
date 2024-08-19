import UIKit
import SwiftUI

final class MeSplitViewController: UISplitViewController {
    init() {
        super.init(style: .doubleColumn)

        // TODO: (wpsidebar) increase size
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let meVC = MeViewController()
        meVC.isSidebarModeEnabled = true
        setViewController(meVC, for: .primary)
    }
}
