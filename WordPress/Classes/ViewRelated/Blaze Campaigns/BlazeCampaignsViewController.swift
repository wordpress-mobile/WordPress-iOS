import UIKit

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
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.register(BlazeCampaignTableViewCell.self, forCellReuseIdentifier: BlazeCampaignTableViewCell.defaultReuseID)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    // MARK: - Properties

    private let blog: Blog

    private var campaigns: [BlazeCampaign] = [] {
        didSet {
            tableView.reloadData()
            updateNoResultsView()
        }
    }

    private var isLoading: Bool = false {
        didSet {
            if isLoading != oldValue {
                updateNoResultsView()
            }
        }
    }

    // MARK: - Initializers

    init(blog: Blog) {
        self.blog = blog
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCampaigns()
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

    private func fetchCampaigns() {
        guard let service = BlazeService() else { return }

        isLoading = true
        service.getRecentCampaigns(for: blog) { [weak self] in
            self?.didFetchCampaigns($0)
        }
    }

    private func didFetchCampaigns(_ result: Result<BlazeCampaignsSearchResponse, Error>) {
        switch result {
        case .success(let response):
            campaigns = response.campaigns ?? []
        case .failure:
            showErrorView()
        }
        isLoading = false
    }

    @objc private func plusButtonTapped() {
        BlazeEventsTracker.trackBlazeFlowStarted(for: .campaignsList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .campaignsList, blog: blog)
    }
}

// MARK: - Table methods

extension BlazeCampaignsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return campaigns.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BlazeCampaignTableViewCell.defaultReuseID) as? BlazeCampaignTableViewCell,
              let campaign = campaigns[safe: indexPath.row] else {
            return UITableViewCell()
        }

        let viewModel = BlazeCampaignViewModel(campaign: campaign)
        cell.configure(with: viewModel, blog: blog)
        return cell
    }
}

// MARK: - No results

extension BlazeCampaignsViewController: NoResultsViewControllerDelegate {

    private func updateNoResultsView() {
        guard !isLoading else {
            showLoadingView()
            return
        }

        if campaigns.isEmpty {
            showNoResultsView()
            return
        }

        hideNoResults()
    }

    private func showNoResultsView() {
        hideNoResults()
        noResultsViewController.hideImageView(true)
        configureAndDisplayNoResults(on: view,
                                     title: Strings.NoResults.emptyTitle,
                                     subtitle: Strings.NoResults.emptySubtitle,
                                     buttonTitle: Strings.promoteButtonTitle)
    }

    private func showErrorView() {
        hideNoResults()
        noResultsViewController.hideImageView(true)
        configureAndDisplayNoResults(on: view,
                                     title: Strings.NoResults.errorTitle,
                                     subtitle: Strings.NoResults.errorSubtitle)
    }

    private func showLoadingView() {
        hideNoResults()
        noResultsViewController.hideImageView(false)
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
