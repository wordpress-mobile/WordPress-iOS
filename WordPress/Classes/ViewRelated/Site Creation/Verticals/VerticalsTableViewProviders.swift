
import UIKit

typealias TableViewProvider = UITableViewDataSource & UITableViewDelegate

typealias SiteVerticalSelectionHandler = ((SiteVertical?) -> ())

// MARK: - DefaultVerticalsTableViewProvider

/// This table view provider fulfills the "happy path" role of data source & delegate for searching Site Verticals.
///
class DefaultVerticalsTableViewProvider: NSObject, TableViewProvider {

    // MARK: DefaultVerticalsTableViewProvider

    private(set) weak var tableView: UITableView?

    var data: [SiteVertical] {
        didSet {
            tableView?.reloadData()
        }
    }

    var selectionHandler: SiteVerticalSelectionHandler?

    init(tableView: UITableView, data: [SiteVertical] = [], selectionHandler: SiteVerticalSelectionHandler? = nil) {
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

        let vertical = data[indexPath.row]
        selectionHandler?(vertical)
    }

    // MARK: Private behavior

    private func addBorder(cell: UITableViewCell, at: IndexPath) {
        let row = at.row
        if row == 0 {
            cell.addTopBorder(withColor: WPStyleGuide.greyLighten20())
        }

        if row == data.count - 1 {
            cell.addBottomBorder(withColor: WPStyleGuide.greyLighten20())
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
