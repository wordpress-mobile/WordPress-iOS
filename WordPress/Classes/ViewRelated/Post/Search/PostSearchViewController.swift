import UIKit
import Combine

// TODO: Add loading and empty states
final class PostSearchViewController: UITableViewController, UISearchResultsUpdating, NSFetchedResultsControllerDelegate {
    private let viewModel: PostSearchViewModel
    private var fetchResultsViewController: NSFetchedResultsController<BasePost> {
        viewModel.fetchResultsController
    }

    init(viewModel: PostSearchViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")

        fetchResultsViewController.delegate = self
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchResultsViewController.fetchedObjects?.count ?? 0
    }

    // TODO: Update new cells and display in sections
    // TODO: Add context menus and navigation (reuse with the plain list)
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
        let post = fetchResultsViewController.object(at: indexPath)
        cell.textLabel?.text = post.titleForDisplay()
        return cell
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text ?? ""
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}
