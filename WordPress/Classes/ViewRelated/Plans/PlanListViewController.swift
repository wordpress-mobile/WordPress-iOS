import UIKit
import WordPressShared

final class PlanListViewController: UITableViewController, ImmuTablePresenter {
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()
    private var viewModel: PlanListViewModel = .Loading {
        didSet {
            handler.viewModel = viewModel.tableViewModelWithPresenter(self, planService: service)
            updateNoResults()
            updateFooterView()
        }
    }

    func updateFooterView() {
        let footerViewModel = viewModel.tableFooterViewModelWithPresenter(self)

        tableView.tableFooterView = tableFooterViewWithViewModel(footerViewModel)
    }

    private var footerTapAction: (() -> Void)?
    private func tableFooterViewWithViewModel(viewModel: (title: NSAttributedString, action: () -> Void)?) -> UIView? {
        guard let viewModel = viewModel else { return nil }

        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: "ToSFooterView", style: .Footer)

        let title = viewModel.title
        footerView.attributedTitle = title
        footerView.frame.size.height = WPTableViewSectionHeaderFooterView.heightForFooter(title.string, width: footerView.bounds.width)

        // Don't add a recognizer if we already have one
        let recognizers = footerView.gestureRecognizers
        if recognizers == nil || recognizers?.count == 0 {
            footerTapAction = viewModel.action

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(footerTapped))
            footerView.addGestureRecognizer(tapRecognizer)
        }

        return footerView
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

    static let restorationIdentifier = "PlanList"

    convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let service = PlanService(blog: blog, store: StoreKitStore()) else {
            return nil
        }
        self.init(siteID: Int(blog.dotComID), service: service)
    }

    let siteID: Int
    let service: PlanService<StoreKitStore>
    init(siteID: Int, service: PlanService<StoreKitStore>) {
        self.siteID = siteID
        self.service = service
        super.init(style: .Grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
        restorationIdentifier = PlanListViewController.restorationIdentifier
        restorationClass = PlanListViewController.self
        noResultsView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        ImmuTable.registerRows([PlanListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModelWithPresenter(self, planService: service)
        updateNoResults()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        service.plansWithPricesForBlog(siteID,
            success: { result in
                self.viewModel = .Ready(result)
            },
            failure: { error in
                self.viewModel = .Error(String(error))
            }
        )
    }

    func footerTapped() {
        footerTapAction?()
    }
}

// MARK: - WPNoResultsViewDelegate

extension PlanListViewController: WPNoResultsViewDelegate {
    func didTapNoResultsView(noResultsView: WPNoResultsView!) {
        SupportViewController.showFromTabBar()
    }
}

// MARK: - UIViewControllerRestoration

extension PlanListViewController: UIViewControllerRestoration {
    struct EncodingKey {
        static let activePlan = "activePlan"
    }
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String where identifier == PlanListViewController.restorationIdentifier else {
            return nil
        }

        // TODO: postpone restoration until view model is stable
        // @koke 2016-03-01
        return nil
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
    }
}
