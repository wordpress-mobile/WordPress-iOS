
import UIKit

/// This table view provider fulfills the "happy path" role of data source & delegate for searching Site Domains.
///
final class WebAddressTableViewProvider: NSObject, TableViewProvider {

    // MARK: WebAddressTableViewProvider

    /// The table view serviced by this provider
    private weak var tableView: UITableView?

    /// Implicit suggestions are the base suggestions based on the site's name and info.
    /// Whenever the user types something, this should be set to false.
    var isShowingImplicitSuggestions = true {
        didSet {
            tableView?.reloadData()
        }
    }

    /// The underlying data represented by the provider
    var data: [DomainSuggestion] {
        didSet {
            tableView?.reloadData()
        }
    }

    /// The closure to invoke when a row in the underlying table view has been selected
    private let selectionHandler: CellSelectionHandler?

    /// Creates a WebAddressTableViewProvider.
    ///
    /// - Parameters:
    ///   - tableView:          the table view to be managed
    ///   - data:               initial data backing the table view
    ///   - selectionHandler:   the action to perform when a cell is selected, if any
    ///
    init(tableView: UITableView, data: [DomainSuggestion] = [], selectionHandler: CellSelectionHandler? = nil) {
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard isShowingImplicitSuggestions else {
            return nil
        }

        return NSLocalizedString("Suggestions", comment: "Suggested domains")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.cellReuseIdentifier()) as? AddressCell else {

            assertionFailure("This is a programming error - AddressCell has not been properly registered!")
            return UITableViewCell()
        }

        let domainSuggestion = data[indexPath.row]
        cell.model = domainSuggestion

        addBorder(cell: cell, at: indexPath)

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectionHandler?(indexPath)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1.0))
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
}
