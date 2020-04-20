
// MARK: - InlineErrorTableViewProvider

typealias InlineErrorMessage = String

typealias CellSelectionHandler = ((IndexPath) -> ())

struct InlineErrorMessages {

    static let noConnection: InlineErrorMessage = NSLocalizedString("No connection",
                                                                       comment: "Displayed during Site Creation, when searching for Verticals and the network is unavailable.")

    static let serverError: InlineErrorMessage = NSLocalizedString("There was a problem",
                                                                   comment: "Displayed during Site Creation, when searching for Verticals and the server returns an error.")
}

/// This table view provider fulfills the data source & delegate responsibilities for inline error cases.
/// It consists of a single cell with an error message and an accessory view with which the user can retry a search.
///
final class InlineErrorTableViewProvider: NSObject, TableViewProvider {

    // MARK: InlineErrorTableViewProvider

    /// The table view serviced by this provider
    private weak var tableView: UITableView?

    /// The message displayed in the empty state table view cell
    private let message: InlineErrorMessage

    /// The closure to invoke when a row in the underlying table view has been selected
    private let selectionHandler: CellSelectionHandler?

    /// Creates an EmptyVerticalsTableViewProvider.
    ///
    /// - Parameters:
    ///   - tableView:          the table view to be managed
    ///   - message:            the message to display in the cell in question
    ///   - selectionHandler:   the retry action to perform when a cell is selected, if any
    ///
    init(tableView: UITableView, message: InlineErrorMessage, selectionHandler: CellSelectionHandler? = nil) {
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier()) as? InlineErrorRetryTableViewCell else {

            assertionFailure("This is a programming error - InlineErrorRetryTableViewCell has not been properly registered!")
            return UITableViewCell()
        }

        cell.setMessage(message)

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectionHandler?(indexPath)
    }
}
