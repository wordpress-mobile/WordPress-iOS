import UIKit
import Combine

final class PostSearchViewController: UIViewController, UITableViewDelegate, UISearchResultsUpdating {
    weak var searchController: UISearchController?

    enum SectionID: Int, CaseIterable {
        case tokens = 0
        case posts
    }

    enum ItemID: Hashable {
        case token(AnyHashable)
        case post(NSManagedObjectID)
    }

    private let tableView = UITableView(frame: .zero, style: .plain)

    private lazy var dataSource = UITableViewDiffableDataSource<SectionID, ItemID> (tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
        self?.tableView(tableView, cellForRowAt: indexPath)
    }

    private let viewModel: PostSearchViewModel

    private var cancellables: [AnyCancellable] = []

    init(viewModel: PostSearchViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        viewModel.didUpdateData = { [weak self] in
            self?.reloadData()
        }

        viewModel.$searchTerm.removeDuplicates().sink { [weak self] in
            if self?.searchController?.searchBar.text != $0 {
                self?.searchController?.searchBar.text = $0
            }
        }.store(in: &cancellables)

        viewModel.$selectedTokens
            .removeDuplicates { $0.map(\.id) == $1.map(\.id) }
            .sink { [weak self] in
                self?.searchController?.searchBar.searchTextField.tokens = $0.map {
                    $0.asSearchToken()
                }
            }.store(in: &cancellables)

        viewModel.$footerState
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdateFooterState($0) }
            .store(in: &cancellables)
    }

    private func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)

        tableView.register(PostSearchTokenTableCell.self, forCellReuseIdentifier: Constants.tokenCellID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.postCellID)

        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.sizeToFitFooterView()
    }

    // MARK: - Data Source

    private func reloadData() {
        assert(Thread.isMainThread)

        var snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()

        snapshot.appendSections([SectionID.tokens])
        let tokenIDs = viewModel.suggestedTokens.map { ItemID.token($0.id) }
        snapshot.appendItems(tokenIDs, toSection: SectionID.tokens)

        snapshot.appendSections([SectionID.posts])
        let postIDs = viewModel.posts.map { ItemID.post($0.objectID) }
        snapshot.appendItems(postIDs, toSection: SectionID.posts)

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionID(rawValue: indexPath.section)! {
        case .tokens:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.tokenCellID, for: indexPath) as! PostSearchTokenTableCell
            let token = viewModel.suggestedTokens[indexPath.row]
            let isLast = indexPath.row == viewModel.suggestedTokens.count - 1
            cell.configure(with: token, isLast: isLast)
            cell.separatorInset = UIEdgeInsets(top: 0, left: view.bounds.size.width, bottom: 0, right: 0) // Hide the native separator
            return cell
        case .posts:
            // TODO: Update the cell design
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.postCellID, for: indexPath)
            let post = viewModel.posts[indexPath.row]
            var configuration = cell.defaultContentConfiguration()
            let title = post.titleForDisplay() ?? ""
            let string = NSMutableAttributedString(string: title, attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body)
            ])
            if let range = title.range(of: viewModel.searchTerm, options: [.caseInsensitive, .diacriticInsensitive]) {
                string.setAttributes([
                    .backgroundColor: UIColor.systemYellow.withAlphaComponent(0.25)
                ], range: NSRange(range, in: title))
            }
            configuration.attributedText = string
            configuration.secondaryText = post.latest().dateStringForDisplay()
            configuration.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = configuration
            return cell
        }
    }

    private func didUpdateFooterState(_ state: PagingFooterView.State?) {
        guard let state else {
            tableView.tableFooterView = nil
            return
        }
        switch state {
        case .loading:
            tableView.tableFooterView = PagingFooterView(state: .loading)
        case .error:
            let footerView = PagingFooterView(state: .error)
            footerView.buttonRetry.addAction(UIAction { [viewModel] _ in
                viewModel.didTapRefreshButton()
            }, for: .touchUpInside)
            tableView.tableFooterView = footerView
        }
        tableView.sizeToFitFooterView()
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SectionID(rawValue: indexPath.section)! {
        case .tokens:
            viewModel.didSelectToken(at: indexPath.row)
        case .posts:
            break // TODO: Show post
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - 500 {
            viewModel.didReachBottom()
        }
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        viewModel.searchTerm = searchBar.text ?? ""
        viewModel.selectedTokens = searchBar.searchTextField.tokens.map {
            $0.representedObject as! PostSearchToken
        }
    }
}

private enum Constants {
    static let postCellID = "postCellID"
    static let tokenCellID = "suggestedTokenCellID"
}
