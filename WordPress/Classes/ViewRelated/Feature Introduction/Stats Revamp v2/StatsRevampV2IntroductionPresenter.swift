import Foundation
import UIKit

/// Presents the StatsRevampV2IntroductionPresenter with an actionable button.
/// The screen also has a button to dismiss the screen itself.
/// - Primary button: take the user to the new Stats Insights screen

class StatsRevampV2IntroductionPresenter: NSObject {

    // MARK: - Properties

    private lazy var navigationController: UINavigationController = {
        let vc = StatsRevampV2FeatureIntroduction()
        vc.presenter = self
        return UINavigationController(rootViewController: vc)
    }()

    // MARK: - Present Feature Introduction

    func present(from presentingViewController: UIViewController) {
        presentingViewController.present(navigationController, animated: true)
    }

    // MARK: - Action Handling

    func primaryButtonSelected() { }
}
