import UIKit

class SiteIntentViewController: CollapsableHeaderViewController {
    private let selection: SiteIntentStep.SiteIntentSelection
    private let tableView: UITableView

    private var selectedVertical: SiteIntentVertical? {
        didSet {
            itemSelectionChanged(selectedVertical != nil)
        }
    }

    private var availableVerticals: [SiteIntentVertical] = SiteIntentData.defaultVerticals

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        WPStyleGuide.configureSearchBar(searchBar)
        searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchBar.backgroundColor = .clear
        return searchBar
    }()

    init(_ selection: @escaping SiteIntentStep.SiteIntentSelection) {
        self.selection = selection

        tableView = UITableView(frame: .zero, style: .grouped)

        super.init(
            scrollableView: tableView,
            mainTitle: Strings.mainTitle,
            prompt: Strings.prompt,
            primaryActionTitle: Strings.primaryAction,
            secondaryActionTitle: nil,
            defaultActionTitle: nil,
            accessoryView: nil
        )

        tableView.dataSource = self
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        navigationItem.backButtonTitle = NSLocalizedString("Topic", comment: "Shortened version of the main title to be used in back navigation")
        configureTable()
        configureSkipButton()
        configureCloseButton()
        largeTitleView.numberOfLines = 2
        SiteCreationAnalyticsHelper.trackSiteIntentViewed()
    }

    // MARK: Constants

    private enum Strings {
        static let mainTitle: String = NSLocalizedString("What's your website about?", comment: "Select the site's intent. Title")
        static let prompt: String = NSLocalizedString("Choose a topic from the list below or type your own", comment: "Select the site's intent. Subtitle")
        static let primaryAction: String = NSLocalizedString("Continue", comment: "Button to progress to the next step")
    }

    // MARK: UI Setup

    private func configureTable() {
        tableView.backgroundColor = .basicBackground
    }

    private func configureSkipButton() {
        let skip = UIBarButtonItem(title: NSLocalizedString("Skip", comment: "Continue without making a selection"), style: .done, target: self, action: #selector(skipButtonTapped))
        navigationItem.rightBarButtonItem = skip
    }

    private func configureCloseButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Cancel site creation"), style: .done, target: self, action: #selector(closeButtonTapped))
    }

    private func setupTable() {
        setupCells()
    }

    private func setupCells() {
        let cellName = IntentCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellName)
        tableView.register(InlineErrorRetryTableViewCell.self, forCellReuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
        tableView.cellLayoutMarginsFollowReadableWidth = true
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
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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
