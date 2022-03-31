import UIKit

class SiteIntentViewController: CollapsableHeaderViewController {
    private let selection: SiteIntentStep.SiteIntentSelection
    private let tableView: UITableView

    private var selectedVertical: SiteIntentVertical? {
        didSet {
            itemSelectionChanged(selectedVertical != nil)
        }
    }

    private var availableVerticals: [SiteIntentVertical] = SiteIntentData.defaultVerticals {
        didSet {
            contentSizeWillChange()
        }
    }

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        WPStyleGuide.configureSearchBar(searchBar)
        searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchBar.backgroundColor = .clear
        return searchBar
    }()

    private lazy var continueButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        button.setTitle(Strings.continueButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(navigateToNextStep), for: .touchUpInside)
        return button
    }()

    override var seperatorStyle: SeperatorStyle {
        return .hidden
    }

    init(_ selection: @escaping SiteIntentStep.SiteIntentSelection) {
        self.selection = selection
        tableView = UITableView(frame: .zero, style: .plain)

        super.init(
            scrollableView: tableView,
            mainTitle: Strings.mainTitle,
            navigationBarTitle: Strings.navigationBarTitle,
            prompt: Strings.prompt,
            primaryActionTitle: Strings.primaryAction,
            accessoryView: searchBar
        )

        tableView.dataSource = self
        searchBar.delegate = self
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTable()

        largeTitleView.numberOfLines = Metrics.largeTitleLines
        SiteCreationAnalyticsHelper.trackSiteIntentViewed()

    }

    override func viewDidLayoutSubviews() {
        searchBar.placeholder = Strings.searchTextFieldPlaceholder
    }

    // MARK: UI Setup

    private func configureNavigationBar() {
        // Title
        navigationItem.backButtonTitle = Strings.backButtonTitle
        // Skip button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.skipButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(skipButtonTapped))
        // Cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancelButtonTitle,
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(closeButtonTapped))
    }

    private func configureTable() {
        let cellName = IntentCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellName)
        tableView.register(InlineErrorRetryTableViewCell.self, forCellReuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.backgroundColor = .basicBackground
    }

    // MARK: Actions

    @objc
    private func skipButtonTapped(_ sender: Any) {
        SiteCreationAnalyticsHelper.trackSiteIntentSkipped()
        selection(nil)
    }

    @objc
    private func closeButtonTapped(_ sender: Any) {
        SiteCreationAnalyticsHelper.trackSiteIntentCanceled()
        dismiss(animated: true)
    }
}

// MARK: Constants
extension SiteIntentViewController {

    private enum Strings {
        static let mainTitle = NSLocalizedString("What's your website about?",
                                                 comment: "Select the site's intent. Title")
        static let navigationBarTitle = NSLocalizedString("Site Topic",
                                                          comment: "Title of the navigation bar, shown when the large title is hidden.")
        static let prompt = NSLocalizedString("Choose a topic from the list below or type your own",
                                              comment: "Select the site's intent. Subtitle")
        static let primaryAction = NSLocalizedString("Continue",
                                                     comment: "Button to progress to the next step")
        static let backButtonTitle = NSLocalizedString("Topic",
                                                       comment: "Shortened version of the main title to be used in back navigation")
        static let skipButtonTitle = NSLocalizedString("Skip",
                                                       comment: "Continue without making a selection")
        static let cancelButtonTitle = NSLocalizedString("Cancel",
                                                         comment: "Cancel site creation")
        static let searchTextFieldPlaceholder = NSLocalizedString("Eg. Fashion, Poetry, Politics", comment: "Placeholder text for the search field used for Site Intent selection.")
    }

    private enum Metrics {
        static let searchTextFieldInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let largeTitleLines = 2
    }
}

// MARK: UITableViewDataSource

extension SiteIntentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableVerticals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return configureIntentCell(tableView, cellForRowAt: indexPath)
    }

    func configureIntentCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: IntentCell.cellReuseIdentifier()) as? IntentCell else {
            assertionFailure("This is a programming error - IntentCell has not been properly registered!")
            return UITableViewCell()
        }

        let vertical = availableVerticals[indexPath.row]
        cell.model = vertical
        return cell
    }
}

// MARK: UITableViewDelegate

extension SiteIntentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vertical = availableVerticals[indexPath.row]

        SiteCreationAnalyticsHelper.trackSiteIntentSelected(vertical)
        selection(vertical)
    }
}

extension SiteIntentViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        availableVerticals = SiteIntentData.verticals
        tableView.reloadData()
        tableView.scrollToView(searchBar.searchTextField, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            availableVerticals = SiteIntentData.verticals
            tableView.reloadData()
            return
        }

        let filteredVerticals = availableVerticals.filter {
            $0.localizedTitle.lowercased().contains(searchText.lowercased())
        }

        availableVerticals = filteredVerticals
        tableView.reloadData()
    }
}
