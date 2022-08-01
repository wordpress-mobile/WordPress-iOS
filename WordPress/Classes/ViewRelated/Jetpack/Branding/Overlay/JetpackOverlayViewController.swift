import UIKit

class JetpackOverlayViewController: UIViewController {

    private var redirectAction: (() -> Void)?

    private var viewFactory: ((() -> Void)?) -> UIView

    init(viewFactory: @escaping ((() -> Void)?) -> UIView, redirectAction: (() -> Void)? = nil) {
        self.redirectAction = redirectAction
        self.viewFactory = viewFactory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = viewFactory(redirectAction)
    }

    private func setPreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(size)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setPreferredContentSize()
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
