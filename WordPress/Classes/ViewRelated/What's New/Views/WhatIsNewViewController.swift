
import UIKit

/// UIViewController for the What's New - Feature Announcements scene
class WhatIsNewViewController: UIViewController {

    private let makeWhatIsNewView: () -> WhatIsNewView

    private lazy var whatIsNewView: WhatIsNewView = {
        let view = makeWhatIsNewView()
        view.continueAction = { [weak self] in
            WPAnalytics.track(.featureAnnouncementButtonTapped, properties: ["button": "close_dialog"])
            self?.dismiss(animated: true)
        }
        return view
    }()

    init(whatIsNewViewFactory: @escaping () -> WhatIsNewView) {
        self.makeWhatIsNewView = whatIsNewViewFactory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = whatIsNewView
    }
}
