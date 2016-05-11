import UIKit
import WordPressShared

class PlanDetailViewController: UIViewController {
    private let cellIdentifier = "PlanFeatureListItem"

    private let tableViewHorizontalMargin: CGFloat = 24.0
    private let planImageDropshadowRadius: CGFloat = 3.0

    private var tableViewModel = ImmuTable.Empty {
        didSet {
            tableView?.reloadData()
        }
    }
    var viewModel: PlanDetailViewModel! {
        didSet {
            tableViewModel = viewModel.tableViewModel
            title = viewModel.plan.title
            accessibilityLabel = viewModel.plan.fullTitle
            if isViewLoaded() {
                populateHeader()
                updateNoResults()
            }
        }
    }

    private let noResultsView = WPNoResultsView()

    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        } else {
            hideNoResults()
        }
    }
    func showNoResults(viewModel: WPNoResultsView.Model) {
        noResultsView.bindViewModel(viewModel)
        if noResultsView.isDescendantOfView(tableView) {
            noResultsView.centerInSuperview()
        } else {
            tableView.addSubviewWithFadeAnimation(noResultsView)
        }
    }

    func hideNoResults() {
        noResultsView.removeFromSuperview()
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var planImageView: UIImageView!
    @IBOutlet weak var dropshadowImageView: UIImageView!
    @IBOutlet weak var planTitleLabel: UILabel!
    @IBOutlet weak var planDescriptionLabel: UILabel!
    @IBOutlet weak var planPriceLabel: UILabel!
    @IBOutlet weak var purchaseButton: UIButton?
    @IBOutlet weak var separator: UIView!

    private lazy var currentPlanLabel: UIView = {
        let label = UILabel()
        label.font = WPFontManager.systemSemiBoldFontOfSize(13.0)
        label.textColor = WPStyleGuide.validGreen()
        label.text = NSLocalizedString("Current Plan", comment: "").uppercaseStringWithLocale(NSLocale.currentLocale())
        label.translatesAutoresizingMaskIntoConstraints = false

        // Wrapper view required for spacing to work out correctly, as the header stackview
        // is baseline-based, and so acts differently for a label vs view.
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        wrapper.pinSubviewToAllEdges(label)

        return wrapper
    }()

    class func controllerWithPlan(plan: Plan, siteID: Int, activePlan: Plan, price: String) -> PlanDetailViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanDetailViewController

        controller.viewModel = PlanDetailViewModel(plan: plan, siteID: siteID, activePlan: activePlan, price: price, features: .Loading)

        return controller
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureTableView()
        populateHeader()
        updateNoResults()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        registerForPurchaseNotifications()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        unregisterForPurchaseNotifications()
    }

    private func configureAppearance() {
        planTitleLabel.textColor = WPStyleGuide.darkGrey()
        planDescriptionLabel.textColor = WPStyleGuide.grey()
        planPriceLabel.textColor = WPStyleGuide.grey()

        purchaseButton?.tintColor = WPStyleGuide.wordPressBlue()

        dropshadowImageView.backgroundColor = UIColor.whiteColor()
        configurePlanImageDropshadow()

        separator.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func configureTableView() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80.0
    }

    private func configurePlanImageDropshadow() {
        dropshadowImageView.layer.masksToBounds = false
        dropshadowImageView.layer.shadowColor = WPStyleGuide.greyLighten30().CGColor
        dropshadowImageView.layer.shadowOpacity = 1.0
        dropshadowImageView.layer.shadowRadius = planImageDropshadowRadius
        dropshadowImageView.layer.shadowOffset = .zero
        dropshadowImageView.layer.shadowPath = UIBezierPath(ovalInRect: dropshadowImageView.bounds).CGPath
    }

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var purchaseWrapperView: UIView!

    private func populateHeader() {
        let plan = viewModel.plan
        let iconUrl = viewModel.isActivePlan ? plan.activeIconUrl : plan.iconUrl
        planImageView.downloadResizedImage(iconUrl, placeholderImage: nil, pointSize: planImageView.bounds.size)
        planTitleLabel.text = plan.fullTitle
        planDescriptionLabel.text = plan.tagline
        planPriceLabel.text = viewModel.priceText

        if !viewModel.purchaseButtonVisible {
            purchaseButton?.removeFromSuperview()
        } else {
            purchaseButton?.selected = viewModel.purchaseButtonSelected
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

    private func layoutHeaderIfNeeded() {
        headerView.layoutIfNeeded()

        // Table header views don't automatically resize using Auto Layout,
        // so we need to calculate the correct size to fit the content, update the frame,
        // and then reset the tableHeaderView property so that the new size takes effect.
        let size = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        if size.height != headerView.frame.size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
        }
    }

    //MARK: - IBActions

    @IBAction private func purchaseTapped() {
        guard let identifier = viewModel.plan.productIdentifier else {
            return
        }
        purchaseButton?.selected = true
        let store = StoreKitStore()
        store.getProductsWithIdentifiers(
            Set([identifier]),
            success: { [viewModel] products in
                do {
                    try StoreKitCoordinator.instance.purchaseProduct(products[0], forSite: viewModel.siteID)
                } catch StoreCoordinatorError.PaymentAlreadyInProgress {
                    self.purchaseButton?.selected = false
                } catch {}
            },
            failure: { error in
                DDLogSwift.logError("Error fetching Store products: \(error)")
                self.purchaseButton?.selected = false
        })
    }

    private func registerForPurchaseNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(storeTransactionDidFinish(_:)),
                                                         name: StoreKitCoordinator.TransactionDidFinishNotification,
                                                         object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(storeTransactionDidFail(_:)),
                                                         name: StoreKitCoordinator.TransactionDidFailNotification,
                                                         object: nil)
    }

    private func unregisterForPurchaseNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: StoreKitCoordinator.TransactionDidFinishNotification,
                                                            object: nil)

        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: StoreKitCoordinator.TransactionDidFailNotification,
                                                            object: nil)
    }

    @objc private func storeTransactionDidFinish(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
        let productID = userInfo[StoreKitCoordinator.NotificationProductIdentifierKey] as? String else { return }

        if productID == viewModel.plan.productIdentifier {
            purchaseButton?.selected = false

            let postPurchaseViewController = PlanPostPurchaseViewController(plan: viewModel.plan)
            presentViewController(postPurchaseViewController, animated: true, completion: nil)
        }
    }

    @objc private func storeTransactionDidFail(notification: NSNotification) {
        purchaseButton?.selected = false

        if let userInfo = notification.userInfo,
            let productID = userInfo[StoreKitCoordinator.NotificationProductIdentifierKey] as? String,
            let error = userInfo[NSUnderlyingErrorKey] as? NSError
            where productID == viewModel.plan.productIdentifier {
            let alert = UIAlertController(title: NSLocalizedString("Purchase Failed", comment: "Title of alert displayed when an in-app purchase couldn't be completed."),
                                          message: error.localizedDescription,
                                          preferredStyle: .Alert)
            alert.addActionWithTitle(NSLocalizedString("Dismiss", comment: "Dismiss a view. Verb."), style: .Cancel, handler: nil)
            alert.presentFromRootViewController()
        }
    }
}

// MARK: Table View Data Source / Delegate
extension PlanDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableViewModel.sections.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewModel.sections[section].rows.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = tableViewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(row.reusableIdentifier, forIndexPath: indexPath)

        row.configureCell(cell)

        return cell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? FeatureItemCell else { return }

        let separatorInset: CGFloat = 15
        let isLastCellInSection = indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1
        let isLastSection = indexPath.section == self.numberOfSectionsInTableView(tableView) - 1

        // The separator for the last cell in each section has no insets,
        // except for in the last section, where there's no separator at all.
        if isLastCellInSection {
            if isLastSection {
                cell.separator.hidden = true
            } else {
                cell.separatorInset = UIEdgeInsetsZero
            }
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: separatorInset, bottom: 0, right: separatorInset)
        }
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableViewModel.sections[section].headerText
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = self.tableView(tableView, titleForHeaderInSection: section) where !title.isEmpty {
            let header = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
            header.title = title
            return header
        } else {
            return nil
        }
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let headerView = self.tableView(tableView, viewForHeaderInSection: section) as? WPTableViewSectionHeaderFooterView {
            return WPTableViewSectionHeaderFooterView.heightForHeader(headerView.title, width: CGRectGetWidth(view.bounds))
        } else {
            return 0
        }
    }
}
