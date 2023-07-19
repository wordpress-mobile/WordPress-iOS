import UIKit
import SwiftUI
import WordPressUI

final class CompliancePopoverViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: CompliancePopoverViewModel

    // MARK: - Views
    private let hostingController: UIHostingController<CompliancePopover>

    private var contentView: UIView {
        return hostingController.view
    }

    private var bannerIntrinsicHeight: CGFloat = 0

    init(viewModel: CompliancePopoverViewModel) {
        self.viewModel = viewModel
        hostingController = UIHostingController(rootView: CompliancePopover(viewModel: self.viewModel))
        super.init(nibName: nil, bundle: nil)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addContentView()
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        hostingController.rootView.goToSettingsAction = {
            self.viewModel.didTapSettings()
        }
        hostingController.rootView.saveAction = {
            self.viewModel.didTapSave()
        }
        viewModel.didDisplayPopover()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: view.bounds.width, height: 0)
        let contentViewSize = contentView.systemLayoutSizeFitting(targetSize)
        self.contentView.frame = .init(origin: .zero, size: contentViewSize)
        self.preferredContentSize = contentView.bounds.size

        self.hostingController.rootView.screenHeight = self.view.frame.height
        self.hostingController.rootView.shouldScroll = (contentViewSize.height + 100) > self.view.frame.height
    }

    private func addContentView() {
        self.hostingController.willMove(toParent: self)
        self.addChild(hostingController)
        self.view.addSubview(contentView)
        self.hostingController.didMove(toParent: self)
    }
}

// MARK: - DrawerPresentable
extension CompliancePopoverViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        }
        return .intrinsicHeight
    }

    var allowsUserTransition: Bool {
        return false
    }

    var allowsDragToDismiss: Bool {
        false
    }

    var allowsTapToDismiss: Bool {
        return false
    }
}
