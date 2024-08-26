import UIKit
import SwiftUI

final class MeSplitViewController: UISplitViewController {
    init() {
        super.init(style: .doubleColumn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presentsWithGesture = false

        let meVC = MeViewController()
        meVC.isSidebarModeEnabled = true
        setViewController(meVC, for: .primary)
    }
}
