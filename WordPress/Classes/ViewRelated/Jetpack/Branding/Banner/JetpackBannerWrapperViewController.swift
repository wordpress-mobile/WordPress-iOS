import Foundation
import UIKit

@objc class JetpackBannerWrapperViewController: UIViewController {
    var childVC: UIViewController?

    @objc convenience init(childVC: UIViewController) {
        self.init()
        self.childVC = childVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)

        if let childVC = childVC {
            addChild(childVC)
            stackView.addArrangedSubview(childVC.view)
            childVC.didMove(toParent: self)
        }

        let jetpackBannerView = JetpackBannerView()
        stackView.addArrangedSubview(jetpackBannerView)
        jetpackBannerView.heightAnchor.constraint(greaterThanOrEqualToConstant: JetpackBannerView.minimumHeight).isActive = true
    }
}
