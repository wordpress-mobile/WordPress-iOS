import Foundation
import UIKit
import WordPressShared

class JetpackBannerWrapperViewController: UIViewController {
    /// The wrapped child view controller.
    private(set) var childVC: UIViewController?
    private var screen: JetpackBannerScreen?

    convenience init(
        childVC: UIViewController,
        screen: JetpackBannerScreen? = nil
    ) {
        self.init()
        self.childVC = childVC
        self.screen = screen
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView()
        configureStackView(stackView)
        configureChildVC(stackView)
        configureJetpackBanner(stackView)
        configureNavigationItem()
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
        let textProvider = JetpackBrandingTextProvider(screen: screen)
        let jetpackBannerView = JetpackBannerView()
        jetpackBannerView.configure(title: textProvider.brandingText()) { [unowned self] in
            JetpackBrandingCoordinator.presentOverlay(from: self)
            if let screen = screen {
                JetpackBrandingAnalyticsHelper.trackJetpackPoweredBannerTapped(screen: screen)
            }
        }
        stackView.addArrangedSubview(jetpackBannerView)
        if let childVC = childVC as? JPScrollViewDelegate {
            childVC.addTranslationObserver(jetpackBannerView)
        }
    }

    private func configureNavigationItem() {
        navigationItem.title = childVC?.navigationItem.title
    }
}
