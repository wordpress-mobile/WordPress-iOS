import UIKit
import SwiftUI
import WordPressUI
import JetpackStats

/// Base class for site stats table view controllers
///
class SiteStatsBaseTableViewController: UIViewController {

    let refreshControl = UIRefreshControl()

    var tableStyle: UITableView.Style { .insetGrouped }

    private(set) lazy var tableView = UITableView(frame: .zero, style: tableStyle)

    override func viewDidLoad() {
        super.viewDidLoad()

        initTableView()

        if #available(iOS 26, *) {
            registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
                self.updateTableViewLayoutMargins()
            }
            updateTableViewLayoutMargins()
        }
    }

    @available(iOS 26, *)
    private func updateTableViewLayoutMargins() {
        let inset = JetpackStats.Constants.cardHorizontalInset(for: UserInterfaceSizeClass(traitCollection.horizontalSizeClass))
        tableView.directionalLayoutMargins = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
    }

    override func contentScrollView(for edge: NSDirectionalRectEdge) -> UIScrollView? {
        tableView
    }

    func initTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true

        if #available(iOS 26, *) {
            tableView.preservesSuperviewLayoutMargins = false
        }

        view.addSubview(tableView)
        tableView.pinEdges()

        tableView.refreshControl = refreshControl
    }
}

// MARK: - UITableViewDataSource

// These methods aren't actually needed as the tableview is controlled by an instance of ImmuTableViewHandler.
// However, ImmuTableViewHandler requires that the owner of the tableview is a data source and delegate.

extension SiteStatsBaseTableViewController: TableViewContainer, UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if #available(iOS 26, *) { 30 } else { 16 }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }
}
