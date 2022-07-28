import UIKit

class JetpackOverlayViewController: UIViewController {

    private var redirectAction: (() -> Void)?

    init(redirectAction: (() -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.redirectAction = redirectAction
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = JetpackOverlayView(buttonAction: redirectAction)
    }

    private func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(size)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.setNeedsLayout()
    }
}

extension JetpackOverlayViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

extension JetpackOverlayViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .collapsed
    }
}
