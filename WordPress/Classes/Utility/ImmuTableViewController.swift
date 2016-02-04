import UIKit
import RxSwift
import WordPressShared

typealias ImmuTableRowControllerGenerator = ImmuTableRow -> UIViewController

protocol ImmuTablePresenter: class {
    var visible: Observable<Bool> { get }
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

protocol ImmuTableController {
    var presenter: ImmuTablePresenter? { get set }
    var title: String { get }
    var immuTableRows: [ImmuTableRow.Type] { get }
    var immuTable: Observable<ImmuTable> { get }
    var errorMessage: Observable<String?> { get }
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

    let controller: ImmuTableController?

    private let bag = DisposeBag()

    // MARK: - Table View Controller

    init(controller: ImmuTableController? = nil) {
        self.controller = controller
        super.init(style: .Grouped)
        self.controller?.presenter = self
        if let controller = self.controller {
            title = controller.title
            registerRows(controller.immuTableRows)
            controller.immuTable
                .observeOn(MainScheduler.instance)
                .subscribeNext({ [weak self] in
                    self?.handler.viewModel = $0
                    })
                .addDisposableTo(bag)
            controller.errorMessage
                .observeOn(MainScheduler.instance)
                .subscribeNext({ [weak self] in
                    self?.errorMessage = $0
                    })
                .addDisposableTo(bag)
        }
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
