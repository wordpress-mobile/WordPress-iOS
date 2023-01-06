import Foundation
import Combine
import UIKit
import WordPressShared

final class JetpackBannerWrapperViewController: UIViewController {
    /// The wrapped child view controller.
    private(set) var childVC: UIViewController?
    private var screen: JetpackBannerScreen?
    /// JPScrollViewDelegate conformance.
    internal var scrollViewTranslationPublisher = PassthroughSubject<Bool, Never>()

    override var navigationItem: UINavigationItem {
        guard let childVC else { return super.navigationItem }
        return childVC.navigationItem
    }

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

        extendedLayoutIncludesOpaqueBars = true

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
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
        addTranslationObserver(jetpackBannerView)
    }
}

// MARK: JPScrollViewDelegate

extension JetpackBannerWrapperViewController: JPScrollViewDelegate {}
