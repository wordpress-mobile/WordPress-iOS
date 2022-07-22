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
        configureStackView(stackView)
        configureChildVC(stackView)
        configureJetpackBanner(stackView)
    }

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
        guard shouldShowBanner() else { return }

        let jetpackBannerView = JetpackBannerView()
        stackView.addArrangedSubview(jetpackBannerView)
        jetpackBannerView.heightAnchor.constraint(greaterThanOrEqualToConstant: JetpackBannerView.minimumHeight).isActive = true

        if let childVC = childVC as? JPScrollViewDelegate {
            childVC.addTranslationObserver(jetpackBannerView)
        }
    }

    /// Note: This could be improved to be delegated to the wrapped view.
    private func shouldShowBanner() -> Bool {
        return JetpackBrandingVisibility.all.enabled
    }
}
