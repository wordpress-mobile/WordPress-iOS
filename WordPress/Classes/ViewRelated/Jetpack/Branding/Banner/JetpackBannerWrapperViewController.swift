import Foundation
import UIKit

@objc class JetpackBannerWrapperViewController: UIViewController {
    /// The wrapped child view controller.
    private(set) var childVC: UIViewController?

    @objc convenience init(childVC: UIViewController) {
        self.init()
        self.childVC = childVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView()
        configureStackView(stackView)
        configureChildVC(stackView)
        configureJetpackBanner(stackView)
    }

    // MARK: Configuration

    private func configureStackView(_ stackView: UIStackView) {
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)
    }

    private func configureChildVC(_ stackView: UIStackView) {
        guard let childVC = childVC else { return }

        addChild(childVC)
        stackView.addArrangedSubview(childVC.view)
        childVC.didMove(toParent: self)
    }

    private func configureJetpackBanner(_ stackView: UIStackView) {
        guard JetpackBrandingVisibility.all.enabled, !isModal() else {
            return
        }

        let jetpackBannerView = JetpackBannerView() { [unowned self] in
            JetpackBrandingCoordinator.presentOverlay(from: self)
        }
        stackView.addArrangedSubview(jetpackBannerView)

        if let childVC = childVC as? JPScrollViewDelegate {
            childVC.addTranslationObserver(jetpackBannerView)
        }
    }
}
