
import UIKit

/// UIViewController for the What's New - Feature Announcements scene
class WhatIsNewViewController: UIViewController {

    private let makeWhatIsNewView: () -> WhatIsNewView

    private let onContinue: () -> Void
    private let onDismiss: (() -> Void)?

    private lazy var whatIsNewView: WhatIsNewView = {
        let view = makeWhatIsNewView()
        view.continueAction = { [weak self] in
            self?.onContinue()
            self?.dismiss(animated: true)
        }
        view.dismissAction = { [weak self] in
            self?.onDismiss?()
            self?.dismiss(animated: true)
        }
        return view
    }()

    init(whatIsNewViewFactory: @escaping () -> WhatIsNewView, onContinue: @escaping () -> Void, onDismiss: (() -> Void)? = nil) {
        self.makeWhatIsNewView = whatIsNewViewFactory
        self.onContinue = onContinue
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = whatIsNewView
    }
}
