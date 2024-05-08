import UIKit
import SwiftUI
import WordPressUI

class BottomSheetContentViewController: UIViewController {

    // MARK: - Views

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentView: UIView

    private var hostingController: UIViewController?

    // MARK: - Init

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }

    init<T: View>(contentView: T) {
        let hostingController = UIHostingController(rootView: contentView)
        self.contentView = hostingController.view
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if let hostingController {
            self.setupHostingController(hostingController)
        } else {
            self.setupContentView()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else {
            return
        }
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        self.updateContentSize()
        if let presentationController = parent?.presentationController as? DrawerPresentationController {
            presentationController.transition(to: presentationController.currentPosition)
        }
    }

    // MARK: - Setup Content View

    private func setupContentView() {
        self.view.addSubview(scrollView)
        self.view.pinSubviewToAllEdges(scrollView)
        self.contentView.translatesAutoresizingMaskIntoConstraints = true
        self.scrollView.addSubview(contentView)
    }

    private func setupHostingController(_ hostingController: UIViewController) {
        hostingController.willMove(toParent: self)
        self.addChild(hostingController)
        self.setupContentView()
        hostingController.didMove(toParent: self)
    }

    private func updateContentSize() {
        // Calculate the size needed for the view to fit its content
        let targetSize = CGSize(width: view.bounds.width, height: 0)
        self.contentView.frame = CGRect(origin: .zero, size: targetSize)
        let contentViewSize = contentView.systemLayoutSizeFitting(targetSize)
        self.contentView.frame.size = contentViewSize

        // Set the scrollView's content size to match the contentView's size
        //
        // Scroll is enabled / disabled automatically depending on whether the `contentSize` is bigger than the its size.
        self.scrollView.contentSize = contentViewSize

        // Set the preferred content size for the view controller to match the contentView's size
        //
        // This property should be updated when `DrawerPresentable.collapsedHeight` is `intrinsicHeight`.
        // Because under the hood the `BottomSheetViewController` reads this property to layout its subviews.
        self.preferredContentSize = contentViewSize
    }
}

extension BottomSheetContentViewController: DrawerPresentable {

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        }
        return .intrinsicHeight
    }

    var allowsUserTransition: Bool {
        return false
    }
}
