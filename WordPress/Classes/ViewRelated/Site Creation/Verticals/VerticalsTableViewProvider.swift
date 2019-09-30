
import UIKit

typealias CellSelectionHandler = ((IndexPath) -> ())

// MARK: - VerticalsTableViewProvider

/// This table view provider fulfills the "happy path" role of data source & delegate for searching Site Verticals.
///
final class VerticalsTableViewProvider: NSObject, TableViewProvider {

    // MARK: VerticalsTableViewProvider

    /// The table view serviced by this provider
    private weak var tableView: UITableView?

    /// The underlying data represented by the provider
    var data: [SiteVertical] {
        didSet {
            tableView?.reloadData()
        }
    }

    /// The closure to invoke when a row in the underlying table view has been selected
    private let selectionHandler: CellSelectionHandler?

    /// Creates a VerticalsTableViewProvider.
    ///
    /// - Parameters:
    ///   - tableView:          the table view to be managed
    ///   - data:               initial data backing the table view
    ///   - selectionHandler:   the action to perform when a cell is selected, if any
    ///
    init(tableView: UITableView, data: [SiteVertical] = [], selectionHandler: CellSelectionHandler? = nil) {
        self.tableView = tableView
        self.data = data
        self.selectionHandler = selectionHandler

        super.init()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vertical = data[indexPath.row]
        let cell = configureCell(vertical: vertical, indexPath: indexPath)

        addBorder(cell: cell, at: indexPath)

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectionHandler?(indexPath)
    }

    // MARK: Private behavior

    private func addBorder(cell: UITableViewCell, at: IndexPath) {
        let row = at.row
        if row == 0 {
            cell.addTopBorder(withColor: .neutral(.shade10))
        }

        if row == data.count - 1 {
            cell.addBottomBorder(withColor: .neutral(.shade10))
        }
    }

    private func cellIdentifier(vertical: SiteVertical) -> String {
        return vertical.isNew ? NewVerticalCell.cellReuseIdentifier() : VerticalsCell.cellReuseIdentifier()
    }

    private func configureCell(vertical: SiteVertical, indexPath: IndexPath) -> UITableViewCell {
        let identifier = cellIdentifier(vertical: vertical)

        if var cell = tableView?.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SiteVerticalPresenter {
            cell.vertical = vertical

            return cell as! UITableViewCell
        }

        return UITableViewCell()
    }
}
