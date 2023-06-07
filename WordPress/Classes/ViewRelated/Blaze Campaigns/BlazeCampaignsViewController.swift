import UIKit

final class BlazeCampaignsViewController: UIViewController, NoResultsViewHost {

    // MARK: - Views

    private lazy var dismissButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "plus"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(promotePostButtonTapped))
        return button
    }()

    // MARK: - Properties

    private var blog: Blog

    private var isLoading: Bool = false {
        didSet {
            if isLoading != oldValue {
                showNoResultsViewIfNeeded()
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
    }

    private func setupNavBar() {
        title = Strings.navigationTitle
        navigationItem.rightBarButtonItem = dismissButton
    }

    private func setupNoResults() {
        noResultsViewController.delegate = self
    }

    private func fetchCampaigns() {
        isLoading = true

        // FIXME: Call BlazeService
    }

    @objc private func promotePostButtonTapped() {
        // TODO: Track event
        BlazeFlowCoordinator.presentBlaze(in: self, source: .campaignsList, blog: blog)
    }
}

// MARK: - No results

extension BlazeCampaignsViewController: NoResultsViewControllerDelegate {

    private func showNoResultsViewIfNeeded() {
        guard !isLoading else {
            showLoadingView()
            return
        }

        // FIXME: if results aren't empty, hide the no results view and return

        showNoResultsView()
    }

    private func showNoResultsView() {
        hideNoResults()
        noResultsViewController.hideImageView()
        configureAndDisplayNoResults(on: view,
                                     title: NoResults.emptyTitle,
                                     subtitle: NoResults.emptySubtitle,
                                     buttonTitle: Strings.promoteButtonTitle)
    }

    private func showLoadingView() {
        hideNoResults()
        configureAndDisplayNoResults(on: view,
                                     title: NoResults.loadingTitle,
                                     accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    func actionButtonPressed() {
        promotePostButtonTapped()
    }
}

// MARK: - Constants

extension BlazeCampaignsViewController {

    private enum Strings {
        static let navigationTitle = NSLocalizedString("blaze.campaigns.title", value: "Blaze Campaigns", comment: "Title for the screen that allows users to manage their Blaze campaigns.")
        static let promoteButtonTitle = NSLocalizedString("blaze.campaigns.promote.button.title", value: "Promote", comment: "Button title for the button that shows the Blaze flow when tapped.")
    }

    private enum NoResults {
        static let loadingTitle = NSLocalizedString("blaze.campaigns.loading.title", value: "Loading campaigns...", comment: "Displayed while Blaze campaigns are being loaded.")
        static let emptyTitle = NSLocalizedString("blaze.campaigns.empty.title", value: "You have no campaigns", comment: "Title displayed when there are no Blaze campaigns to display.")
        static let emptySubtitle = NSLocalizedString("blaze.campaigns.empty.subtitle", value: "You have not created any campaigns yet. Click promote to get started.", comment: "Text displayed when there are no Blaze campaigns to display.")
    }
}
