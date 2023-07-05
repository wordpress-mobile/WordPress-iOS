import UIKit
import SwiftUI
import WordPressUI

//final class CompliancePopoverViewController: UIHostingController<CompliancePopover> {
//
//    private let viewModel: CompliancePopoverViewModelProtocol
//
//    /// Tracks the banner view intrinsic height.
//    /// Needed to enable it's scrolling when it grows bigger than the screen.
//    ///
//    var bannerIntrinsicHeight: CGFloat = 0
//
//    init(viewModel: CompliancePopoverViewModelProtocol) {
//        self.viewModel = viewModel
//        super.init(rootView: CompliancePopover())
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        rootView.goToSettingsAction = { [weak self] in
//            self?.viewModel.didTapSettings()
//        }
//
//        rootView.saveAction = { [weak self] in
//            self?.viewModel.didTapSave()
//        }
//    }
//
//    /// Needed for protocol conformance.
//    ///
//    required dynamic init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
////    override func viewDidLayoutSubviews() {
////        super.viewDidLayoutSubviews()
////
////        print("Kill me right now")
////        // Make the banner scrollable when the banner height is bigger than the screen height.
////        // Send it in the next run loop to avoid a recursive `viewDidLayoutSubviews`.
////        bannerIntrinsicHeight = view.intrinsicContentSize.height
////        DispatchQueue.main.async {
////            self.rootView.shouldScroll = self.bannerIntrinsicHeight > self.view.frame.height
////        }
////    }
//}

final class CompliancePopoverViewController: UIViewController {

    // MARK: - Views
    private let hostingController: UIViewController = {
        let controller = UIHostingController(rootView: CompliancePopover())
        controller.view.translatesAutoresizingMaskIntoConstraints = true
        return controller
    }()

    private var contentView: UIView {
        return hostingController.view
    }

    private let viewModel: CompliancePopoverViewModelProtocol

    init(viewModel: CompliancePopoverViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addContentView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: view.bounds.width, height: 0)
        let contentViewSize = contentView.systemLayoutSizeFitting(targetSize)
        self.contentView.frame = .init(origin: .zero, size: contentViewSize)
        self.preferredContentSize = contentView.bounds.size
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
        print("89fas9(*")
        return false
    }

    var allowsDragToDismiss: Bool {
        false
    }

    var allowsTapToDismiss: Bool {
        print("AD*SJ*(")
        return false
    }
}
