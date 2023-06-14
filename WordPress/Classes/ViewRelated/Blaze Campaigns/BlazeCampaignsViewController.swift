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
        isLoading = true

        // FIXME: Fetch campaigns via BlazeService

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            self?.campaigns = mockResponse.campaigns ?? []
        }
    }

    @objc private func plusButtonTapped() {
        // TODO: Track event
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

        let viewModel = DashboardBlazeCampaignViewModel(campaign: campaign)
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

private let mockResponse: BlazeCampaignsSearchResponse = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(BlazeCampaignsSearchResponse.self, from: """
    {
        "totalItems": 3,
        "campaigns": [
            {
                "campaign_id": 26916,
                "name": "Test Post - don't approve",
                "start_date": "2023-06-13T00:00:00Z",
                "end_date": "2023-06-01T19:15:45Z",
                "status": "finished",
                "avatar_url": "https://0.gravatar.com/avatar/614d27bcc21db12e7c49b516b4750387?s=96&amp;d=identicon&amp;r=G",
                "budget_cents": 500,
                "target_url": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                "content_config": {
                    "title": "Test Post - don't approve",
                    "snippet": "Test Post Empty Empty",
                    "clickUrl": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                    "imageUrl": "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2"
                },
                "campaign_stats": {
                    "impressions_total": 1000,
                    "clicks_total": 235
                }
            },
            {
                "campaign_id": 1,
                "name": "Test Post - don't approve",
                "start_date": "2023-06-13T00:00:00Z",
                "end_date": "2023-06-01T19:15:45Z",
                "status": "rejected",
                "avatar_url": "https://0.gravatar.com/avatar/614d27bcc21db12e7c49b516b4750387?s=96&amp;d=identicon&amp;r=G",
                "budget_cents": 5000,
                "target_url": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                "content_config": {
                    "title": "Test Post - don't approve",
                    "snippet": "Test Post Empty Empty",
                    "clickUrl": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                    "imageUrl": "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2"
                },
                "campaign_stats": {
                    "impressions_total": 1000,
                    "clicks_total": 235
                }
            },
            {
                "campaign_id": 2,
                "name": "Test Post - don't approve",
                "start_date": "2023-06-13T00:00:00Z",
                "end_date": "2023-06-01T19:15:45Z",
                "status": "active",
                "avatar_url": "https://0.gravatar.com/avatar/614d27bcc21db12e7c49b516b4750387?s=96&amp;d=identicon&amp;r=G",
                "budget_cents": 1000,
                "target_url": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                "content_config": {
                    "title": "Test Post - don't approve",
                    "snippet": "Test Post Empty Empty",
                    "clickUrl": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                    "imageUrl": "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2"
                },
                "campaign_stats": {
                    "impressions_total": 5000,
                    "clicks_total": 1035
                }
            }
        ]
    }
    """.data(using: .utf8)!)
}()
