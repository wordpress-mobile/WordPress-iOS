import UIKit

/// A container UIViewController that adds a Jetpack powered banner at the bottom of the content
class JetpackBannerContainerViewController: UIViewController {

    private let contentController: UIViewController

    @objc init(contentController: UIViewController) {
        self.contentController = contentController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = makeViewWithContent()
    }

    private func makeViewWithContent() -> UIView {
        let jetpackView = JetpackBannerContainerView(frame: .zero)
        addChild(contentController)
        contentController.didMove(toParent: self)
        jetpackView.addViewToContainerView(contentController.view)
        return jetpackView
    }
}
