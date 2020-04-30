class ReaderTagsTableViewController: UIViewController {

    private let style: UITableView.Style

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var viewModel: ReaderTagsTableViewModel?

    init(style: UITableView.Style) {
        self.style = style
        super.init(nibName: nil, bundle: nil)

        viewModel = ReaderTagsTableViewModel(tableView: tableView, presenting: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        view.pinSubviewToAllEdges(tableView)
    }
}
