import UIKit

final class ReferrerDetailsTableViewController: UITableViewController {
    private lazy var tableHandler = ImmuTableViewHandler(takeOver: self)
    private let viewModel = ReferrerDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.Stats.configureTable(tableView)
        buildViewModel()
    }
}

// MARK: - Private Methods
private extension ReferrerDetailsTableViewController {
    func buildViewModel() {

    }
}
