import UIKit
import CocoaLumberjack
import WordPressShared

class PlanDetailViewController: UIViewController {
    fileprivate let cellIdentifier = "PlanFeatureListItem"

    fileprivate let tableViewHorizontalMargin: CGFloat = 24.0
    fileprivate let planImageDropshadowRadius: CGFloat = 3.0

    private var noResultsViewController: NoResultsViewController?
    private var noResultsViewModel: NoResultsViewController.Model?

    fileprivate var tableViewModel = ImmuTable.Empty {
        didSet {
            tableView?.reloadData()
        }
    }
    var viewModel: PlanDetailViewModel! {
        didSet {
            tableViewModel = viewModel.tableViewModel
            title = viewModel.plan.title
            accessibilityLabel = viewModel.plan.fullTitle
            if isViewLoaded {
                populateHeader()
                updateNoResults()
            }
        }
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var planImageView: UIImageView!
    @IBOutlet weak var dropshadowImageView: UIImageView!
    @IBOutlet weak var planTitleLabel: UILabel!
    @IBOutlet weak var planDescriptionLabel: UILabel!
    @IBOutlet weak var planPriceLabel: UILabel!
    @IBOutlet weak var purchaseButton: UIButton?
    @IBOutlet weak var separator: UIView!

    fileprivate lazy var currentPlanLabel: UIView = {
        let label = UILabel()
        label.font = WPFontManager.systemSemiBoldFont(ofSize: 13.0)
        label.textColor = WPStyleGuide.validGreen()
        label.text = NSLocalizedString("Current Plan", comment: "").localizedUppercase
        label.translatesAutoresizingMaskIntoConstraints = false

        // Wrapper view required for spacing to work out correctly, as the header stackview
        // is baseline-based, and so acts differently for a label vs view.
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        wrapper.pinSubviewToAllEdges(label)

        return wrapper
    }()

    class func controllerWithPlan(_ plan: Plan, siteID: Int, activePlan: Plan, price: String) -> PlanDetailViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: NSStringFromClass(self)) as! PlanDetailViewController

        controller.viewModel = PlanDetailViewModel(plan: plan, siteID: siteID, activePlan: activePlan, price: price, features: .loading)

        return controller
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureTableView()
        populateHeader()
        updateNoResults()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerForPurchaseNotifications()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        unregisterForPurchaseNotifications()
    }

    fileprivate func configureAppearance() {
        planTitleLabel.textColor = WPStyleGuide.darkGrey()
        planDescriptionLabel.textColor = WPStyleGuide.grey()
        planPriceLabel.textColor = WPStyleGuide.grey()

        purchaseButton?.tintColor = WPStyleGuide.wordPressBlue()

        dropshadowImageView.backgroundColor = UIColor.white
        configurePlanImageDropshadow()

        separator.backgroundColor = WPStyleGuide.greyLighten30()
    }

    fileprivate func configureTableView() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80.0
    }

    fileprivate func configurePlanImageDropshadow() {
        dropshadowImageView.layer.masksToBounds = false
        dropshadowImageView.layer.shadowColor = WPStyleGuide.greyLighten30().cgColor
        dropshadowImageView.layer.shadowOpacity = 1.0
        dropshadowImageView.layer.shadowRadius = planImageDropshadowRadius
        dropshadowImageView.layer.shadowOffset = .zero
        dropshadowImageView.layer.shadowPath = UIBezierPath(ovalIn: dropshadowImageView.bounds).cgPath
    }

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var purchaseWrapperView: UIView!

    fileprivate func populateHeader() {
        let plan = viewModel.plan
        let iconUrl = viewModel.isActivePlan ? plan.activeIconUrl : plan.iconUrl
        planImageView.downloadResizedImage(from: iconUrl, pointSize: planImageView.bounds.size)
        planTitleLabel.text = plan.fullTitle
        planDescriptionLabel.text = plan.tagline
        planPriceLabel.text = viewModel.priceText

        if !viewModel.purchaseButtonVisible {
            purchaseButton?.removeFromSuperview()
        } else {
            purchaseButton?.isSelected = viewModel.purchaseButtonSelected
        }

        if viewModel.isActivePlan {
            purchaseWrapperView.addSubview(currentPlanLabel)
            purchaseWrapperView.pinSubviewToAllEdgeMargins(currentPlanLabel)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        layoutHeaderIfNeeded()
    }

    fileprivate func layoutHeaderIfNeeded() {
        headerView.layoutIfNeeded()

        // Table header views don't automatically resize using Auto Layout,
        // so we need to calculate the correct size to fit the content, update the frame,
        // and then reset the tableHeaderView property so that the new size takes effect.
        let size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        if size.height != headerView.frame.size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
        }
    }

    // MARK: - IBActions

    @IBAction fileprivate func purchaseTapped() {
        guard let identifier = viewModel.plan.productIdentifier else {
            return
        }
        purchaseButton?.isSelected = true
        let store = StoreKitStore()
        store.getProductsWithIdentifiers(
            Set([identifier]),
            success: { [viewModel] products in
                do {
                    try StoreKitCoordinator.instance.purchaseProduct(products[0], forSite: (viewModel?.siteID)!)
                } catch StoreCoordinatorError.paymentAlreadyInProgress {
                    self.purchaseButton?.isSelected = false
                } catch {}
            },
            failure: { error in
                DDLogError("Error fetching Store products: \(error)")
                self.purchaseButton?.isSelected = false
        })
    }

    fileprivate func registerForPurchaseNotifications() {
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(storeTransactionDidFinish(_:)),
                                                         name: NSNotification.Name(rawValue: StoreKitCoordinator.TransactionDidFinishNotification),
                                                         object: nil)

        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(storeTransactionDidFail(_:)),
                                                         name: NSNotification.Name(rawValue: StoreKitCoordinator.TransactionDidFailNotification),
                                                         object: nil)
    }

    fileprivate func unregisterForPurchaseNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                            name: NSNotification.Name(rawValue: StoreKitCoordinator.TransactionDidFinishNotification),
                                                            object: nil)

        NotificationCenter.default.removeObserver(self,
                                                            name: NSNotification.Name(rawValue: StoreKitCoordinator.TransactionDidFailNotification),
                                                            object: nil)
    }

    @objc fileprivate func storeTransactionDidFinish(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
        let productID = userInfo[StoreKitCoordinator.NotificationProductIdentifierKey] as? String else { return }

        if productID == viewModel.plan.productIdentifier {
            purchaseButton?.isSelected = false

            let postPurchaseViewController = PlanPostPurchaseViewController(plan: viewModel.plan)
            present(postPurchaseViewController, animated: true, completion: nil)
        }
    }

    @objc fileprivate func storeTransactionDidFail(_ notification: Foundation.Notification) {
        purchaseButton?.isSelected = false

        if let userInfo = notification.userInfo,
            let productID = userInfo[StoreKitCoordinator.NotificationProductIdentifierKey] as? String,
            let error = userInfo[NSUnderlyingErrorKey] as? NSError, productID == viewModel.plan.productIdentifier {
            let alert = UIAlertController(title: NSLocalizedString("Purchase Failed", comment: "Title of alert displayed when an in-app purchase couldn't be completed."),
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addActionWithTitle(NSLocalizedString("Dismiss", comment: "Dismiss a view. Verb."), style: .cancel, handler: nil)
            alert.presentFromRootViewController()
        }
    }

}

// MARK: Table View Data Source / Delegate

extension PlanDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return noResultsViewModel != nil ? 1 : tableViewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noResultsViewModel != nil ? 1 : tableViewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard noResultsViewModel != nil,
            let noResultsViewController = noResultsViewController else {
                return tableView.estimatedRowHeight
        }

        return noResultsViewController.heightForTableCell()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell

        if noResultsViewModel != nil {
            cell = noResultsCell()
        } else {
            let row = tableViewModel.rowAtIndexPath(indexPath)
            cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)
            row.configureCell(cell)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? FeatureItemCell else { return }

        let separatorInset: CGFloat = 15
        let isLastCellInSection = indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1
        let isLastSection = indexPath.section == self.numberOfSections(in: tableView) - 1

        // The separator for the last cell in each section has no insets,
        // except for in the last section, where there's no separator at all.
        if isLastCellInSection {
            if isLastSection {
                cell.separator.isHidden = true
            } else {
                cell.separatorInset = UIEdgeInsets.zero
            }
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: separatorInset, bottom: 0, right: separatorInset)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return noResultsViewModel != nil ? nil : tableViewModel.sections[section].headerText
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }
}

// MARK: - No Results Handling Private Extension

private extension PlanDetailViewController {

    func updateNoResults() {
        noResultsViewController?.removeFromView()
        self.noResultsViewModel = nil

        if let noResultsViewModel = viewModel.noResultsViewModel {
            self.noResultsViewModel = noResultsViewModel
        }
    }


    func noResultsCell() -> UITableViewCell {
        let cell = UITableViewCell()
        addNoResultsTo(cell: cell)
        return cell
    }

    func addNoResultsTo(cell: UITableViewCell) {
        noResultsViewController?.removeFromView()

        if noResultsViewController == nil {
            noResultsViewController = NoResultsViewController.controller()
            noResultsViewController?.delegate = self
        }

        guard let noResultsViewController = noResultsViewController,
            let noResultsViewModel = noResultsViewModel else {
                return
        }

        noResultsViewController.bindViewModel(noResultsViewModel)
        noResultsViewController.view.backgroundColor =  .white
        noResultsViewController.view.frame = cell.frame
        cell.contentView.addSubview(noResultsViewController.view)
        addChildViewController(noResultsViewController)
        noResultsViewController.didMove(toParentViewController: self)
    }

}

// MARK: - NoResultsViewControllerDelegate

extension PlanDetailViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}
