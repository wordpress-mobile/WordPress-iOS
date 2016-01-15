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

final class ImmuTableViewController: UITableViewController, ImmuTablePresenter {
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    let willAppear: Observable<Void> = PublishSubject()
    private var willAppearSubject: PublishSubject<Void> {
        return willAppear as! PublishSubject<Void>
    }

    // MARK: - Table View Controller

    init() {
        super.init(style: .Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        willAppearSubject.onNext()
    }

    // MARK: - Inputs

    func bindViewModel(viewModel: ImmuTable) {
        handler.viewModel = viewModel
    }

    func registerRows(rows: [ImmuTableRow.Type]) {
        ImmuTable.registerRows(rows, tableView: tableView)
    }
}
