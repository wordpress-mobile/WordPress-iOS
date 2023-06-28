import UIKit
import SVProgressHUD
import WordPressKit

final class BlazeCampaignsViewController: UIViewController, NoResultsViewHost {
    // MARK: - Views

    private lazy var plusButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "plus"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(plusButtonTapped))
        return button
    }()

    private lazy var tableView: UITableView = {
        // Using grouped style to disable sticky section footers
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 128
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl
        tableView.register(BlazeCampaignTableViewCell.self, forCellReuseIdentifier: BlazeCampaignTableViewCell.defaultReuseID)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private let refreshControl = UIRefreshControl()
    private let footerView = BlazeCampaignFooterView()

    // MARK: - Properties

    private var stream: BlazeCampaignsStream
    private var state: BlazeCampaignsStream.State { stream.state }
    private let blog: Blog

    // MARK: - Initializers

    init(blog: Blog) {
        self.blog = blog
        self.stream = BlazeCampaignsStream(blog: blog)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // This VC is designed to be initialized programmatically.
        fatalError("init(coder:) has not been implemented")
    }

    enum Cell {
        case campaign(BlazeCampaign)
        case spinner
        case error
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupNavBar()
        setupNoResults()

        refreshControl.addTarget(self, action: #selector(pullToRefreshInvoked), for: .valueChanged)
        footerView.onRetry = { [weak self] in self?.loadNextPage() }

        configure(with: stream)
        loadNextPage()
    }

    private func loadNextPage() {
        Task {
            await stream.load()
        }
    }

    @objc private func pullToRefreshInvoked() {
        Task {
            let stream = BlazeCampaignsStream(blog: blog)
            await stream.load()
            if let error = stream.state.error {
                SVProgressHUD.showDismissibleError(withStatus: error.localizedDescription)
            } else {
                configure(with: stream)
            }
            refreshControl.endRefreshing()
        }
    }

    private func configure(with newStream: BlazeCampaignsStream) {
        stream.didChangeState = nil
        stream = newStream
        stream.didChangeState = { [weak self] _ in self?.reloadView() }
        reloadView()
    }

    // MARK: View reload

    private func reloadView() {
        reloadStateView()
        reloadFooterView()
        tableView.reloadData()
    }

    private func reloadStateView() {
        hideNoResults()
        noResultsViewController.hideImageView(true)
        if state.campaigns.isEmpty {
            if state.isLoading {
                noResultsViewController.hideImageView(false)
                showLoadingView()
            } else if state.error != nil {
                showErrorView()
            } else {
                showNoResultsView()
            }
        }
    }

    private func reloadFooterView() {
        if !state.campaigns.isEmpty {
            if state.isLoading {
                footerView.state = .loading
            } else if state.error != nil {
                footerView.state = .error
            } else {
                footerView.state = .empty
            }
        } else {
            footerView.state = .empty
        }
    }

    // MARK: - Private helpers

    private func setupView() {
        view.backgroundColor = .DS.Background.primary
        view.addSubview(tableView)
        view.pinSubviewToAllEdges(tableView)
    }

    private func setupNavBar() {
        title = Strings.navigationTitle
        navigationItem.rightBarButtonItem = plusButton
    }

    private func setupNoResults() {
        noResultsViewController.delegate = self
    }

    @objc private func plusButtonTapped() {
        BlazeEventsTracker.trackBlazeFlowStarted(for: .campaignsList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .campaignsList, blog: blog)
    }
}

// MARK: - Table methods

extension BlazeCampaignsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.campaigns.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BlazeCampaignTableViewCell.defaultReuseID) as? BlazeCampaignTableViewCell,
              let campaign = state.campaigns[safe: indexPath.row] else {
            return UITableViewCell()
        }

        let viewModel = BlazeCampaignViewModel(campaign: campaign)
        cell.configure(with: viewModel, blog: blog)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        footerView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - 500 {
            if state.error == nil {
                loadNextPage()
            }
        }
    }
}

// MARK: - No results

extension BlazeCampaignsViewController: NoResultsViewControllerDelegate {

    private func showNoResultsView() {
        configureAndDisplayNoResults(on: view,
                                     title: Strings.NoResults.emptyTitle,
                                     subtitle: Strings.NoResults.emptySubtitle,
                                     buttonTitle: Strings.promoteButtonTitle)
    }

    private func showErrorView() {
        configureAndDisplayNoResults(on: view,
                                     title: Strings.NoResults.errorTitle,
                                     subtitle: Strings.NoResults.errorSubtitle)
    }

    private func showLoadingView() {
        configureAndDisplayNoResults(on: view,
                                     title: Strings.NoResults.loadingTitle,
                                     accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    func actionButtonPressed() {
        BlazeFlowCoordinator.presentBlaze(in: self, source: .campaignsList, blog: blog)
    }
}

// MARK: - Constants

private extension BlazeCampaignsViewController {

    enum Strings {
        static let navigationTitle = NSLocalizedString("blaze.campaigns.title", value: "Blaze Campaigns", comment: "Title for the screen that allows users to manage their Blaze campaigns.")
        static let promoteButtonTitle = NSLocalizedString("blaze.campaigns.promote.button.title", value: "Promote", comment: "Button title for the button that shows the Blaze flow when tapped.")

        enum NoResults {
            static let loadingTitle = NSLocalizedString("blaze.campaigns.loading.title", value: "Loading campaigns...", comment: "Displayed while Blaze campaigns are being loaded.")
            static let emptyTitle = NSLocalizedString("blaze.campaigns.empty.title", value: "You have no campaigns", comment: "Title displayed when there are no Blaze campaigns to display.")
            static let emptySubtitle = NSLocalizedString("blaze.campaigns.empty.subtitle", value: "You have not created any campaigns yet. Click promote to get started.", comment: "Text displayed when there are no Blaze campaigns to display.")
            static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading Blaze campiagns.")
            static let errorSubtitle = NSLocalizedString("There was an error loading campaigns.", comment: "Text displayed when there is a failure loading Blaze campaigns.")
        }
    }
}
