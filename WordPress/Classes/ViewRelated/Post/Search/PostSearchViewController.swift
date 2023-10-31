import UIKit
import Combine

final class PostSearchViewController: UIViewController, UITableViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    weak var searchController: UISearchController?
    weak var listViewController: AbstractPostListViewController?

    private typealias SectionID = PostSearchViewModel.SectionID
    private typealias ItemID = PostSearchViewModel.ItemID

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

    func configure(_ searchController: UISearchController) {
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.showsSearchResultsController = true

        self.searchController = searchController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        bindViewModel()
    }

    private func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)

        tableView.register(PostSearchTokenTableCell.self, forCellReuseIdentifier: Constants.tokenCellID)
        tableView.register(PostListCell.self, forCellReuseIdentifier: Constants.postCellID)
        tableView.register(PageListCell.self, forCellReuseIdentifier: Constants.pageCellID)

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 0
    }

    private func bindViewModel() {
        viewModel.$snapshot.sink { [weak self] in
            self?.dataSource.apply($0, animatingDifferences: $0.reloadedItemIdentifiers.count == 1)
            self?.updateSuggestedTokenCells()
        }.store(in: &cancellables)

        viewModel.$searchTerm.removeDuplicates().sink { [weak self] in
            if self?.searchController?.searchBar.text != $0 {
                self?.searchController?.searchBar.text = $0
            }
            self?.updateHighlightsForVisibleCells(searchTerm: $0)
        }.store(in: &cancellables)

        viewModel.$selectedTokens
            .removeDuplicates { $0.map(\.id) == $1.map(\.id) }
            .sink { [weak self] in
                self?.searchController?.searchBar.searchTextField.tokens = $0.map {
                    $0.asSearchToken()
                }
            }.store(in: &cancellables)

        viewModel.$footerState
            .throttle(for: 0.33, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdateFooterState($0) }
            .store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.sizeToFitFooterView()
    }

    // MARK: - UITableViewDataSource

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
            let post = viewModel.posts[indexPath.row].latest()
            switch post {
            case let post as Post:
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.postCellID, for: indexPath) as! PostListCell
                assert(listViewController is InteractivePostViewDelegate)
                let viewModel = PostListItemViewModel(post: post)
                cell.configure(with: viewModel, delegate: listViewController as? InteractivePostViewDelegate)
                updateHighlights(for: [cell], searchTerm: self.viewModel.searchTerm)
                return cell
            case let page as Page:
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.pageCellID, for: indexPath) as! PageListCell
                cell.configure(with: PageListItemViewModel(page: page), delegate: listViewController as? InteractivePostViewDelegate)
                updateHighlights(for: [cell], searchTerm: viewModel.searchTerm)
                return cell
            default:
                fatalError("Unsupported item: \(type(of: post))")
            }
        }
    }

    // The diffable data source prevents the reloads of the existing cells
    private func updateSuggestedTokenCells() {
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            if let cell = tableView.cellForRow(at: indexPath) as? PostSearchTokenTableCell {
                let isLast = indexPath.row == viewModel.suggestedTokens.count - 1
                cell.configure(isLast: isLast)
            }
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
            // TODO: Move to viewWillAppear (the way editor is displayed doesn't allow)
            tableView.deselectRow(at: indexPath, animated: true)

            switch viewModel.posts[indexPath.row].latest() {
            case let post as Post:
                guard post.status != .trash else { return }
                (listViewController as! PostListViewController)
                    .edit(post)
            case let page as Page:
                guard page.status != .trash else { return }
                (listViewController as! PageListViewController)
                    .edit(page)
            default:
                fatalError("Unsupported post")
            }
            break // TODO: Show post
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - 500 {
            viewModel.didReachBottom()
        }
    }

    // MARK: - UISearchControllerDelegate

    func willPresentSearchController(_ searchController: UISearchController) {
        viewModel.willStartSearching()
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        viewModel.searchTerm = searchBar.text ?? ""
        viewModel.selectedTokens = searchBar.searchTextField.tokens.map {
            $0.representedObject as! PostSearchToken
        }
    }

    // MARK: - Highlighter

    private func updateHighlightsForVisibleCells(searchTerm: String) {
        let cells = (tableView.indexPathsForVisibleRows ?? [])
            .compactMap(tableView.cellForRow)
        updateHighlights(for: cells, searchTerm: searchTerm)
    }

    private func updateHighlights(for cells: [UITableViewCell], searchTerm: String) {
        let terms = searchTerm
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        for cell in cells {
            guard let cell = cell as? PostSearchResultCell else { continue }

            assert(cell.attributedText != nil)
            let string = NSMutableAttributedString(attributedString: cell.attributedText ?? .init())
            PostSearchViewModel.highlight(terms: terms, in: string)
            cell.attributedText = string
        }
    }
}

private enum Constants {
    static let postCellID = "postCellID"
    static let pageCellID = "pageCellID"
    static let tokenCellID = "suggestedTokenCellID"
}

protocol PostSearchResultCell: AnyObject {
    var attributedText: NSAttributedString? { get set }
}
