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
            title = viewModel.plan.name
            accessibilityLabel = viewModel.plan.name
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
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var headerContainerView: UIView!

    fileprivate lazy var currentPlanLabel: UIView = {
        let label = UILabel()
        label.font = WPFontManager.systemSemiBoldFont(ofSize: 13.0)
        label.textColor = .success
        label.text = NSLocalizedString("Current Plan", comment: "Label title. Refers to the current WordPress.com plan for a user's site.").localizedUppercase
        label.translatesAutoresizingMaskIntoConstraints = false

        // Wrapper view required for spacing to work out correctly, as the header stackview
        // is baseline-based, and so acts differently for a label vs view.
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        wrapper.pinSubviewToAllEdges(label)

        return wrapper
    }()

    class func controllerWithPlan(_ plan: Plan, features: [PlanFeature]) -> PlanDetailViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: NSStringFromClass(self)) as! PlanDetailViewController
        controller.viewModel = PlanDetailViewModel(plan: plan, features: .ready(features))
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

    fileprivate func configureAppearance() {
        view.backgroundColor = .basicBackground
        tableView.backgroundColor = .basicBackground

        planTitleLabel.textColor = .primary
        planDescriptionLabel.textColor = .text
        dropshadowImageView.backgroundColor = UIColor.white
        configurePlanImageDropshadow()

        separator.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth).isActive = true
        separator.backgroundColor = .divider

        headerView.backgroundColor = .listBackground
        headerContainerView.backgroundColor = .listBackground
    }

    fileprivate func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80.0
    }

    fileprivate func configurePlanImageDropshadow() {
        dropshadowImageView.layer.masksToBounds = false
        dropshadowImageView.layer.shadowColor = UIColor.neutral(.shade5).cgColor
        dropshadowImageView.layer.shadowOpacity = 1.0
        dropshadowImageView.layer.shadowRadius = planImageDropshadowRadius
        dropshadowImageView.layer.shadowOffset = .zero
        dropshadowImageView.layer.shadowPath = UIBezierPath(ovalIn: dropshadowImageView.bounds).cgPath
    }

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var purchaseWrapperView: UIView!

    fileprivate func populateHeader() {
        let plan = viewModel.plan
        if let iconURL = URL(string: plan.icon) {
            planImageView.downloadResizedImage(from: iconURL, placeholderImage: UIImage(named: "plan-placeholder")!, pointSize: planImageView.bounds.size)
        } else {
            planImageView.image = UIImage(named: "plan-placeholder")
        }
        planTitleLabel.text = plan.name
        planDescriptionLabel.text = plan.tagline
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
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if size.height != headerView.frame.size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
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
                return UITableView.automaticDimension
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

        cell.contentView.backgroundColor = .listForeground
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return noResultsViewModel != nil ? nil : tableViewModel.sections[section].headerText
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
        addChild(noResultsViewController)
        noResultsViewController.didMove(toParent: self)
    }

}

// MARK: - NoResultsViewControllerDelegate

extension PlanDetailViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}
