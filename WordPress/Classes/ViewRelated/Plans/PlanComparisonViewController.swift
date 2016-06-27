import UIKit
import Gridicons
import WordPressShared

class PlanComparisonViewController: PagedViewController {
    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: Gridicon.iconOfType(.Cross), style: .Plain, target: self, action: #selector(PlanComparisonViewController.closeTapped))
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")

        return button
    }()

    @IBAction func closeTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = cancelXButton
        fetchFeatures()
    }

    let siteID: Int
    let pricedPlans: [PricedPlan]
    let activePlan: Plan
    let initialPlan: Plan
    let service: PlanService<StoreKitStore>

    // Keep a more specific reference to the view controllers rather than force
    // downcast viewControllers.
    private let detailViewControllers: [PlanDetailViewController]

    init(sitePricedPlans: SitePricedPlans, initialPlan: Plan, service: PlanService<StoreKitStore>) {
        self.siteID = sitePricedPlans.siteID
        self.pricedPlans = sitePricedPlans.availablePlans
        self.activePlan = sitePricedPlans.activePlan
        self.initialPlan = initialPlan
        self.service = service

        let viewControllers: [PlanDetailViewController] = pricedPlans.map({ (plan, price) in
            let controller = PlanDetailViewController.controllerWithPlan(plan, siteID: sitePricedPlans.siteID, activePlan: sitePricedPlans.activePlan, price: price)

            return controller
        })
        self.detailViewControllers = viewControllers

        let initialIndex = pricedPlans.indexOf { plan, _ in
            return plan == initialPlan
        }

        super.init(viewControllers: viewControllers, initialIndex: initialIndex!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func fetchFeatures() {
        service.updateAllPlanFeatures(
            success: { [weak self, service] features in
                self?.detailViewControllers.forEach { controller in
                    let plan = controller.viewModel.plan
                    do {
                        let groups = try service.featureGroupsForPlan(plan, features: features)
                        controller.viewModel = controller.viewModel.withFeatures(.Ready(groups))
                    } catch {
                        controller.viewModel = controller.viewModel.withFeatures(.Error(String(error)))
                    }
                }
            }, failure: { [weak self] error in
                self?.detailViewControllers.forEach { controller in
                    controller.viewModel = controller.viewModel.withFeatures(.Error(String(error)))
                }
            })
    }
}
