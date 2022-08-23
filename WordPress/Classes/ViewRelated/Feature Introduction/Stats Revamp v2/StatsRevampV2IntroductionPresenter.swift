import Foundation
import UIKit

/// Presents the StatsRevampV2IntroductionPresenter with an actionable button.
/// The screen also has a button to dismiss the screen itself.
/// - Primary button: take the user to the new Stats Insights screen

class StatsRevampV2IntroductionPresenter: NSObject {

    weak var presentingViewController: UIViewController? = nil

    // MARK: - Properties

    static var hasPresented: Bool {
        get {
            UserPersistentStoreFactory.instance().bool(forKey: Constants.statsRevampV2FeatureIntroDisplayedKey)
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: Constants.statsRevampV2FeatureIntroDisplayedKey)
        }
    }

    private lazy var navigationController: UINavigationController = {
        let vc = StatsRevampV2FeatureIntroduction()
        vc.presenter = self
        return UINavigationController(rootViewController: vc)
    }()

    // MARK: - Present Feature Introduction

    func present(from presentingViewController: UIViewController) {
        StatsRevampV2IntroductionPresenter.hasPresented = true
        self.presentingViewController = presentingViewController

        presentingViewController.present(navigationController, animated: true)
    }

    // MARK: - Action Handling

    func primaryButtonSelected() {
        presentingViewController?.dismiss(animated: true)

        guard let blog = WPTabBarController.sharedInstance().currentOrLastBlog() else {
            return
        }

        WPTabBarController.sharedInstance().mySitesCoordinator.showStats(for: blog, timePeriod: .insights)
    }

    // "Remind Me" prompt
    func secondaryButtonSelected() {
        StatsRevampV2IntroductionPresenter.hasPresented = false
        presentingViewController?.dismiss(animated: true)
    }

    func dismissButtonSelected() {
        presentingViewController?.dismiss(animated: true)
    }

    struct Constants {
        static let statsRevampV2FeatureIntroDisplayedKey = "stats_revamp_v2_feature_intro_displayed"
    }
}

extension WPTabBarController {
    @objc public func showStatsRevampV2FeatureIntroduction() {
        guard FeatureFlag.statsNewInsights.enabled,
              let blog = currentOrLastBlog(),
              blog.isAccessibleThroughWPCom(),
              presentedViewController == nil,
              selectedViewController?.presentedViewController == nil,
              !StatsRevampV2IntroductionPresenter.hasPresented else {
            return
        }

        StatsRevampV2IntroductionPresenter().present(from: selectedViewController ?? self)
    }
}
