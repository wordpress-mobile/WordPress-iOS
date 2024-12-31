import UIKit
import SwiftUI
import WordPressUI

final class CompliancePopoverViewController: UIHostingController<CompliancePopover> {
    private let viewModel: CompliancePopoverViewModel

    init(viewModel: CompliancePopoverViewModel) {
        self.viewModel = viewModel
        super.init(rootView: CompliancePopover(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel.didDisplayPopover()
    }
}
