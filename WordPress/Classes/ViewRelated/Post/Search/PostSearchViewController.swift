import UIKit
import Combine

final class PostSearchViewController: UITableViewController, UISearchResultsUpdating, NSFetchedResultsControllerDelegate {
    private let viewModel: PostSearchViewModel

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

        viewModel.objectDidChange = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    // MARK: - UITableViewController

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfPosts
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
        let post = viewModel.posts(at: indexPath)
        cell.textLabel?.text = post.titleForDisplay()
        return cell
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchTerm = searchController.searchBar.text ?? ""
    }
}
