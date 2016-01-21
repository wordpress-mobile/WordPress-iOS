import UIKit
import RxSwift
import WordPressShared

typealias ImmuTableRowControllerGenerator = ImmuTableRow -> UIViewController

protocol ImmuTablePresenter: AnyObject {
    func push(controllerGenerator: ImmuTableRowControllerGenerator) -> ImmuTableAction
}

extension ImmuTablePresenter where Self: UIViewController {
    func push(controllerGenerator: ImmuTableRowControllerGenerator) -> ImmuTableAction {
        return {
            [unowned self] in
            let controller = controllerGenerator($0)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

/// Generic view controller to present ImmuTable-based tables
///
/// Instead of subclassing the view controller, this is designed to be used from
/// a "controller" class that handles all the logic, and updates the view
/// controller, like you would update a view.
final class ImmuTableViewController: UITableViewController, ImmuTablePresenter {
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private var visibleSubject = PublishSubject<Bool>()

    private var errorAnimator: ErrorAnimator!

    // MARK: - Table View Controller

    init() {
        super.init(style: .Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        errorAnimator = ErrorAnimator(target: view)

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        errorAnimator.layout()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        visibleSubject.on(.Next(true))
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        visibleSubject.on(.Next(false))
    }

    // MARK: - Inputs

    /// Sets the view model for the view controller
    func bindViewModel(viewModel: ImmuTable) {
        handler.viewModel = viewModel
    }

    /// Registers custom rows
    /// - seealso: ImmuTable.registerRows(_:tableView)
    func registerRows(rows: [ImmuTableRow.Type]) {
        ImmuTable.registerRows(rows, tableView: tableView)
    }

    var errorMessage: String? = nil {
        didSet {
            errorAnimator.animateErrorMessage(errorMessage)
        }
    }

    // MARK: - Outputs

    /// Emits a value when the view controller appears or disappears
    var visible: Observable<Bool> {
        return visibleSubject
    }
}
