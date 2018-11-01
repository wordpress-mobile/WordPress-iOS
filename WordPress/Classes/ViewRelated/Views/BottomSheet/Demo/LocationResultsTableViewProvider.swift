
import UIKit

// MARK: - LocationResultsMessages

struct LocationResultsMessages {

    static let noSearch = NSLocalizedString("Start typing your business name or address", comment: "Displayed before the user has conducted a search.")

    static let noMatches = NSLocalizedString("No location matching your search", comment: "Displayed when user has conducted a search with no matches.")
}

// MARK: - LocationResultsTableViewProvider

typealias LocationResultsSearchCompletionHandler = (_ resultSummary: String?) -> Void

class LocationResultsTableViewProvider: NSObject {

    // MARK: Properties

    private(set) var results: [LocationResult]? = nil

    private(set) var selectedIndexPath: IndexPath?

    weak var tableView: UITableView? {
        didSet {
            guard let tableView = tableView else { return }
            configure(tableView: tableView)
        }
    }

    // MARK: Behavior

    func performSearch(query: String, completionHandler: LocationResultsSearchCompletionHandler? = nil) {
        results = LocationResult.demoResults

        let message: String?
        if let results = results, results.isEmpty == false {
            message = nil
        } else {
            message = LocationResultsMessages.noMatches
        }

        DispatchQueue.main.async { [weak self] in
            completionHandler?(message)
            self?.tableView?.reloadData()
        }
    }
}

// MARK: UITableViewDataSource

extension LocationResultsTableViewProvider: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LocationResultTableViewCell.reuseIdentifier, for: indexPath) as? LocationResultTableViewCell
            else { fatalError("Expected a `LocationResultTableViewCell") }

        configure(cell, forRowAt: indexPath)

        return cell
    }
}

// MARK: UITableViewDelegate

extension LocationResultsTableViewProvider: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) else {
            return
        }
        selectedIndexPath = indexPath
        selectedCell.accessoryType = .checkmark
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) else {
            return
        }
        selectedCell.accessoryType = .none
    }
}

// MARK: - Private behavior

private extension LocationResultsTableViewProvider {

    func configure(tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(LocationResultTableViewCell.self, forCellReuseIdentifier: LocationResultTableViewCell.reuseIdentifier)
        tableView.reloadData()
    }

    func configure(_ cell: LocationResultTableViewCell, forRowAt indexPath: IndexPath) {
        guard let locationResult = results?[indexPath.row] else {
            return
        }

        cell.setKey(key: locationResult.name)
        cell.setValue(value: locationResult.locationDescription)

        if selectedIndexPath == indexPath {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
}
