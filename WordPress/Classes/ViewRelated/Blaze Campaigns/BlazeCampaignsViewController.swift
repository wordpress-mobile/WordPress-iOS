import UIKit
import WordPressKit
import WordPressFlux
import DesignSystem

final class BlazeCampaignsViewController: UIViewController, NoResultsViewHost, BlazeCampaignsStreamDelegate {
    // MARK: - Views

    private lazy var createButton = UIBarButtonItem(
        title: Strings.createButtonTitle,
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

    private let refreshControl = UIRefreshControl()

    // MARK: - Properties

    private var stream: BlazeCampaignsStream
    private var pendingStream: AnyObject?
    private let source: BlazeSource
    private let blog: Blog

    // MARK: - Initializers

    init(source: BlazeSource, blog: Blog) {
        self.source = source
        self.blog = blog
        self.stream = BlazeCampaignsStream(blog: blog)
        super.init(nibName: nil, bundle: nil)
    }

    @objc class func makeWithSource(_ source: BlazeSource, blog: Blog) -> BlazeCampaignsViewController {
        BlazeCampaignsViewController(source: source, blog: blog)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BlazeEventsTracker.trackCampaignListOpened(for: source)
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
        BlazeEventsTracker.trackBlazeFlowStarted(for: .campaignList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .campaignList, blog: blog)
    }

    // MARK: - Private

    private func setupView() {
        view.backgroundColor = .DS.Background.primary
        view.addSubview(tableView)
        view.pinSubviewToAllEdges(tableView)
    }

    private func setupNavBar() {
        title = Strings.navigationTitle
        navigationItem.rightBarButtonItem = createButton
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
        BlazeFlowCoordinator.presentBlazeCampaignDetails(in: self, source: .campaignList, blog: blog, campaignID: campaign.campaignID)
    }
}

// MARK: - No results

extension BlazeCampaignsViewController: NoResultsViewControllerDelegate {

    private func showNoResultsView() {
        configureAndDisplayNoResults(on: view,
                                     title: Strings.NoResults.emptyTitle,
                                     subtitle: Strings.NoResults.emptySubtitle,
                                     buttonTitle: Strings.createButtonTitle)
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
        buttonCreateCampaignTapped()
    }
}

// MARK: - Constants

private extension BlazeCampaignsViewController {

    enum Strings {
        static let navigationTitle = NSLocalizedString("blaze.campaigns.title", value: "Blaze Campaigns", comment: "Title for the screen that allows users to manage their Blaze campaigns.")
        static let createButtonTitle = NSLocalizedString("blaze.campaigns.create.button.title", value: "Create", comment: "Button title for the button that shows the Blaze flow when tapped.")

        enum NoResults {
            static let loadingTitle = NSLocalizedString("blaze.campaigns.loading.title", value: "Loading campaigns...", comment: "Displayed while Blaze campaigns are being loaded.")
            static let emptyTitle = NSLocalizedString("blaze.campaigns.empty.title", value: "You have no campaigns", comment: "Title displayed when there are no Blaze campaigns to display.")
            static let emptySubtitle = NSLocalizedString("blaze.campaigns.empty.subtitle", value: "You have not created any campaigns yet. Click create to get started.", comment: "Text displayed when there are no Blaze campaigns to display.")
            static let errorTitle = NSLocalizedString("blaze.campaigns.errorTitle", value: "Oops", comment: "Title for the view when there's an error loading Blaze campiagns.")
            static let errorSubtitle = NSLocalizedString("blaze.campaigns.errorMessage", value: "There was an error loading campaigns.", comment: "Text displayed when there is a failure loading Blaze campaigns.")
        }
    }
}
