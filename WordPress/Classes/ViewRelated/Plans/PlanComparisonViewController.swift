import UIKit
import WordPressShared

class PlanComparisonViewController: PagedViewController {
    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "gridicons-cross"), style: .Plain, target: self, action: #selector(PlanComparisonViewController.closeTapped))
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
            let isActive = sitePricedPlans.activePlan == plan
            let controller = PlanDetailViewController.controllerWithPlan(plan, siteID: sitePricedPlans.siteID, isActive: isActive, price: price)

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
        service.updateAllPlanFeatures({ [weak self] in
            self?.detailViewControllers.forEach { controller in
                let groups = PlanFeatureGroup.groupsForPlan(controller.viewModel.plan)
                // TODO: Avoid the optional groups
                controller.viewModel = controller.viewModel.withFeatures(.Ready(groups!))
            }
            }, failure: { [weak self] error in
                self?.detailViewControllers.forEach { controller in
                    controller.viewModel = controller.viewModel.withFeatures(.Error(String(error)))
                }
            })
    }
}
