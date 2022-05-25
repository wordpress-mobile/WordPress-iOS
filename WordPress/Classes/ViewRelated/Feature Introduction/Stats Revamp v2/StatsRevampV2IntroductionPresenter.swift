import Foundation
import UIKit

/// Presents the StatsRevampV2IntroductionPresenter with actionable buttons
/// and directs the flow according to which action button is tapped.
/// - Try it: take the user to the new Stats Insights screen
/// - Remind me: TO-DO

class StatsRevampV2IntroductionPresenter: NSObject {

    // MARK: - Properties

    private lazy var navigationController: UINavigationController = {
        let vc = StatsRevampV2FeatureIntroduction()
        vc.presenter = self
        return UINavigationController(rootViewController: vc)
    }()

    private lazy var selectedBlog: Blog? = {
        return AccountService(managedObjectContext: ContextManager.shared.mainContext).defaultWordPressComAccount()?.visibleBlogs.first
    }()

    // MARK: - Present Feature Introduction

    func present(from presentingViewController: UIViewController) {
        presentingViewController.present(navigationController, animated: true)
    }

    // MARK: - Action Handling

    func primaryButtonSelected() { }
}
