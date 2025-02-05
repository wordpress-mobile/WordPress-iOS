import UIKit
import WordPressUI

final class ReaderCommentsTableViewController: UIViewController {
    let tableView = UITableView(frame: .zero, style: .plain)
    let padingFooterView = PagingFooterView(state: .loading)

    private let commentCellReuseID = "commentCellReuseID"

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupTableView()
    }

    private func setupTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.preservesSuperviewLayoutMargins = true

        if Feature.enabled(.readerCommentsWebKit) {
            // We use this to mask the initial WebKit warmup that takes a bit of time
            // the first time you initialize a web view. It renders asynchronously, and
            // we don't want to show cells with empty messages.
            tableView.alpha = 0.0
        }

        let nib = UINib(nibName: CommentContentTableViewCell.classNameWithoutNamespaces(), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: commentCellReuseID)

        tableView.separatorStyle = .singleLine
        tableView.separatorInsetReference = .fromAutomaticInsets

        // Hide cell separator for the last row
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0))

        setTableLoadingFooterHidden(true)

        view.addSubview(tableView)
        tableView.pinEdges()
    }

    @objc func setLoadingFooterHidden(_ isHidden: Bool) {
        if isHidden {
            // Hide cell separator for the last row
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0))
        } else {
            tableView.tableFooterView = PagingFooterView(state: .loading)
            tableView.sizeToFitFooterView()
        }
    }
}

// TODO: (kean)
// - Remove estimatedRowHeights
