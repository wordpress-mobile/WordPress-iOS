import UIKit
import Gridicons
import WordPressShared

class PlanComparisonViewController: PagedViewController {

    let initialPlan: Plan
    let plans: [Plan]
    let features: [PlanFeature]

    // Keep a more specific reference to the view controllers rather than force
    // downcast viewControllers.
    fileprivate let detailViewControllers: [PlanDetailViewController]

    lazy fileprivate var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: .gridicon(.cross), style: .plain, target: self, action: #selector(PlanComparisonViewController.closeTapped))
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")

        return button
    }()

    init(plans: [Plan], initialPlan: Plan, features: [PlanFeature]) {
        self.initialPlan = initialPlan
        self.plans = plans
        self.features = features

        let controllers: [PlanDetailViewController] = plans.map({ plan in
            let controller = PlanDetailViewController.controllerWithPlan(plan, features: features)
            return controller
        })
        self.detailViewControllers = controllers

        let initialIndex = plans.firstIndex { plan in
            return plan == initialPlan
        }

        super.init(viewControllers: controllers, initialIndex: initialIndex!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func closeTapped() {
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = cancelXButton
    }

}
