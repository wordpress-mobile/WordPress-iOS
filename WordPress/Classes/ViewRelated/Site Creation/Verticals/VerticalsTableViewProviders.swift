
import UIKit

typealias TableViewProvider = UITableViewDataSource & UITableViewDelegate

typealias SiteVerticalSelectionHandler = ((SiteVertical?) -> ())

// MARK: - DefaultVerticalsTableViewProvider

/// This table view provider fulfills the "happy path" role of data source & delegate for searching Site Verticals.
///
final class DefaultVerticalsTableViewProvider: NSObject, TableViewProvider {

    // MARK: DefaultVerticalsTableViewProvider

    /// The table view serviced by this provider
    private weak var tableView: UITableView?

    /// The underlying data represented by the provider
    var data: [SiteVertical] {
        didSet {
            tableView?.reloadData()
        }
    }

    /// The closure to invoke when a row in the underlying table view has been selected
    private let selectionHandler: SiteVerticalSelectionHandler?

    /// Creates a DefaultVerticalsTableViewProvider.
    ///
    /// - Parameters:
    ///   - tableView:          the table view to be managed
    ///   - data:               initial data backing the table view
    ///   - selectionHandler:   the action to perform when a cell is selected, if any
    ///
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

// MARK: - EmptyVerticalsTableViewProvider

typealias EmptyVerticalsMessage = String

struct EmptyVerticalsMessages {

    static let noConnection: EmptyVerticalsMessage = NSLocalizedString("No connection",
                                                                       comment: "Displayed during Site Creation, when searching for Verticals and the network is unavailable.")

    static let networkError: EmptyVerticalsMessage = NSLocalizedString("There was a problem",
                                                                       comment: "Displayed during Site Creation, when searching for Verticals and the server returns an error.")
}

/// This table view provider fulfills the error-state role of data source & delegate for searching Site Verticals.
/// It consists of a single cell with an error message and an accessory view with which the user can retry a search.
///
final class EmptyVerticalsTableViewProvider: NSObject, TableViewProvider {

    // MARK: EmptyVerticalsTableViewProvider

    /// The table view serviced by this provider
    private weak var tableView: UITableView?

    /// The message displayed in the empty state table view cell
    private let message: EmptyVerticalsMessage

    /// The closure to invoke when a row in the underlying table view has been selected
    private let selectionHandler: SiteVerticalSelectionHandler?

    /// Creates an EmptyVerticalsTableViewProvider.
    ///
    /// - Parameters:
    ///   - tableView:          the table view to be managed
    ///   - message:            the message to display in the cell in question
    ///   - selectionHandler:   the retry action to perform when a cell is selected, if any
    ///
    init(tableView: UITableView, message: EmptyVerticalsMessage, selectionHandler: SiteVerticalSelectionHandler? = nil) {
        self.tableView = tableView
        self.message = message
        self.selectionHandler = selectionHandler

        super.init()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VerticalErrorRetryTableViewCell.cellReuseIdentifier()) as? VerticalErrorRetryTableViewCell else {

            assertionFailure("This is a programming error - VerticalErrorRetryTableViewCell has not been properly registered!")
            return UITableViewCell()
        }

        cell.setMessage(message)

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectionHandler?(nil)
    }
}
