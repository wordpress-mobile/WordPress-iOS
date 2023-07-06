import UIKit
import WordPressKit
import WordPressFlux

final class BlazeCampaignsViewController: UIViewController, NoResultsViewHost, BlazeCampaignsStreamDelegate {
    // MARK: - Views

    private lazy var plusButton = UIBarButtonItem(
        image: UIImage(systemName: "plus"),
        style: .plain,
        target: self,
        action: #selector(buttonCreateCampaignTapped)
    )

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 128
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(setNeedsToRefreshCampaigns), for: .valueChanged)
        tableView.register(BlazeCampaignTableViewCell.self, forCellReuseIdentifier: BlazeCampaignTableViewCell.defaultReuseID)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var promoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonCreateCampaignTapped), for: .touchUpInside)

        var configuration = UIButton.Configuration.filled()
        configuration.title = Strings.promoteButtonTitle
        configuration.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        configuration.imagePlacement = .leading
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = UIColor(
            light: UIColor(fromHex: 0xFDFDFD),
            dark: UIColor(fromHex: 0x202020)
        )
        configuration.baseForegroundColor = .jetpackGreen
        button.configuration = configuration

        return button
    }()

    private let refreshControl = UIRefreshControl()

    // MARK: - Properties

    private var stream: BlazeCampaignsStream
    private var pendingStream: AnyObject?
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

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupNavBar()
        setupNoResults()

        stream.delegate = self
        stream.load()

        // Refresh data automatically when new campaign is created
        NotificationCenter.default.addObserver(self, selector: #selector(setNeedsToRefreshCampaigns), name: .blazeCampaignCreated, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.sizeToFitFooterView()
    }

    // MARK: - Stream

    func stream(_ stream: BlazeCampaignsStream, didAppendItemsAt indexPaths: [IndexPath]) {
        // Make sure the existing cells are not reloaded to avoid interfering with image loading
        UIView.performWithoutAnimation {
            tableView.insertRows(at: indexPaths, with: .none)
        }
    }

    func streamDidRefreshState(_ stream: BlazeCampaignsStream) {
        reloadView()
    }

    private func reloadView() {
        reloadStateView()
        reloadFooterView()
        tableView.sizeToFitFooterView()
    }

    private func reloadStateView() {
        hideNoResults()
        noResultsViewController.hideImageView(true)
        if stream.campaigns.isEmpty {
            if stream.isLoading {
                noResultsViewController.hideImageView(false)
                showLoadingView()
            } else if stream.error != nil {
                showErrorView()
            } else {
                showNoResultsView()
            }
        }
    }

    private func reloadFooterView() {
        guard !stream.campaigns.isEmpty else {
            tableView.tableFooterView = nil
            return
        }
        if stream.isLoading {
            tableView.tableFooterView = PagingFooterView(state: .loading)
        } else if stream.error != nil {
            let footerView = PagingFooterView(state: .error)
            footerView.buttonRetry.addTarget(self, action: #selector(buttonRetryTapped), for: .touchUpInside)
            tableView.tableFooterView = footerView
        } else {
            tableView.tableFooterView = nil
        }
    }

    // MARK: - Actions

    @objc private func buttonRetryTapped() {
        stream.load()
    }

    @objc private func setNeedsToRefreshCampaigns() {
        guard pendingStream == nil else { return }

        let stream = BlazeCampaignsStream(blog: blog)
        stream.load { [weak self] in
            guard let self else { return }
            switch $0 {
            case .success:
                self.stream = stream
                self.stream.delegate = self
                self.tableView.reloadData()
                self.reloadView()
            case .failure(let error):
                if self.refreshControl.isRefreshing {
                    ActionDispatcher.dispatch(NoticeAction.post(Notice(title: error.localizedDescription, feedbackType: .error)))
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                self.pendingStream = nil
                self.refreshControl.endRefreshing()
            }
        }
        pendingStream = stream
    }

    @objc private func buttonCreateCampaignTapped() {
        BlazeEventsTracker.trackBlazeFlowStarted(for: .campaignsList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .campaignsList, blog: blog)
    }

    // MARK: - Private

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
}

// MARK: - Table methods

extension BlazeCampaignsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        stream.campaigns.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlazeCampaignTableViewCell.defaultReuseID) as! BlazeCampaignTableViewCell
        let campaign = stream.campaigns[indexPath.row]
        let viewModel = BlazeCampaignViewModel(campaign: campaign)
        cell.configure(with: viewModel, blog: blog)
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - 500 {
            if stream.error == nil {
                stream.load()
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let campaign = stream.campaigns[safe: indexPath.row] else {
            return
        }
        BlazeFlowCoordinator.presentBlazeCampaignDetails(in: self, source: .campaignsList, blog: blog, campaignID: campaign.campaignID)
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

    enum Metrics {
        static let promoteButtonHeight: CGFloat = 55
    }

    enum Strings {
        static let navigationTitle = NSLocalizedString("blaze.campaigns.title", value: "Blaze Campaigns", comment: "Title for the screen that allows users to manage their Blaze campaigns.")
        static let promoteButtonTitle = NSLocalizedString("blaze.campaigns.promote.button.title", value: "Promote", comment: "Button title for the button that shows the Blaze flow when tapped.")

        enum NoResults {
            static let loadingTitle = NSLocalizedString("blaze.campaigns.loading.title", value: "Loading campaigns...", comment: "Displayed while Blaze campaigns are being loaded.")
            static let emptyTitle = NSLocalizedString("blaze.campaigns.empty.title", value: "You have no campaigns", comment: "Title displayed when there are no Blaze campaigns to display.")
            static let emptySubtitle = NSLocalizedString("blaze.campaigns.empty.subtitle", value: "You have not created any campaigns yet. Click promote to get started.", comment: "Text displayed when there are no Blaze campaigns to display.")
            static let errorTitle = NSLocalizedString("blaze.campaigns.errorTitle", value: "Oops", comment: "Title for the view when there's an error loading Blaze campiagns.")
            static let errorSubtitle = NSLocalizedString("blaze.campaigns.errorMessage", value: "There was an error loading campaigns.", comment: "Text displayed when there is a failure loading Blaze campaigns.")
        }
    }
}
