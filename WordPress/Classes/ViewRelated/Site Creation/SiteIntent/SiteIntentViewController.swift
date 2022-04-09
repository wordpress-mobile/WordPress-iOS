import UIKit

class SiteIntentViewController: CollapsableHeaderViewController {
    private let selection: SiteIntentStep.SiteIntentSelection
    private let tableView: UITableView

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
        searchBar.searchTextField.returnKeyType = .search
        return searchBar
    }()

    override var separatorStyle: SeparatorStyle {
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

    override func estimatedContentSize() -> CGSize {

        let visibleCells = CGFloat(availableVerticals.count)
        let height = visibleCells * IntentCell.estimatedSize.height
        return CGSize(width: view.frame.width, height: height)
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
        static let searchTextFieldPlaceholder = NSLocalizedString("Eg. Fashion, Poetry, Politics", comment: "Placeholder text for the search field int the Site Intent screen.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title of the continue button for the Site Intent screen.")
    }

    private enum Metrics {
        static let largeTitleLines = 2
        static let continueButtonPadding: CGFloat = 16
        static let continueButtonBottomOffset: CGFloat = 12
        static let continueButtonHeight: CGFloat = 44
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

// MARK: Search Bar Delegate
extension SiteIntentViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // do not unfilter already filtered content, when navigating back to this page
        SiteCreationAnalyticsHelper.trackSiteIntentSearchFocused()
        guard availableVerticals == SiteIntentData.defaultVerticals else {
            return
        }

        availableVerticals = SiteIntentData.allVerticals
        tableView.reloadData()
        tableView.scrollToView(searchBar.searchTextField, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        availableVerticals = SiteIntentData.filterVerticals(with: searchText)
        tableView.reloadData()
    }
}

fileprivate struct SiteIntentData {

    static let allVerticals: [SiteIntentVertical] = [
        .init("food", NSLocalizedString("Food", comment: "Food site intent topic"), "🍔", isDefault: true),
        .init("news", NSLocalizedString("News", comment: "News site intent topic"), "🗞️", isDefault: true),
        .init("lifestyle", NSLocalizedString("Lifestyle", comment: "Lifestyle site intent topic"), "☕", isDefault: true),
        .init("personal", NSLocalizedString("Personal", comment: "Personal site intent topic"), "✍️", isDefault: true),
        .init("photography", NSLocalizedString("Photography", comment: "Photography site intent topic"), "📷", isDefault: true),
        .init("travel", NSLocalizedString("Travel", comment: "Travel site intent topic"), "✈️", isDefault: true),
        .init("art", NSLocalizedString("Art", comment: "Art site intent topic"), "🎨"),
        .init("automotive", NSLocalizedString("Automotive", comment: "Automotive site intent topic"), "🚗"),
        .init("beauty", NSLocalizedString("Beauty", comment: "Beauty site intent topic"), "💅"),
        .init("books", NSLocalizedString("Books", comment: "Books site intent topic"), "📚"),
        .init("business", NSLocalizedString("Business", comment: "Business site intent topic"), "💼"),
        .init("community_nonprofit", NSLocalizedString("Community & Non-Profit", comment: "Community & Non-Profit site intent topic"), "🤝"),
        .init("education", NSLocalizedString("Education", comment: "Education site intent topic"), "🏫"),
        .init("diy", NSLocalizedString("DIY", comment: "DIY site intent topic"), "🔨"),
        .init("fashion", NSLocalizedString("Fashion", comment: "Fashion site intent topic"), "👠"),
        .init("finance", NSLocalizedString("Finance", comment: "Finance site intent topic"), "💰"),
        .init("film_television", NSLocalizedString("Film & Television", comment: "Film & Television site intent topic"), "🎥"),
        .init("fitness_exercise", NSLocalizedString("Fitness & Exercise", comment: "Fitness & Exercise site intent topic"), "💪"),
        .init("gaming", NSLocalizedString("Gaming", comment: "Gaming site intent topic"), "🎮"),
        .init("health", NSLocalizedString("Health", comment: "Health site intent topic"), "❤️"),
        .init("interior_design", NSLocalizedString("Interior Design", comment: "Interior Design site intent topic"), "🛋️"),
        .init("local_services", NSLocalizedString("Local Services", comment: "Local Services site intent topic"), "📍"),
        .init("music", NSLocalizedString("Music", comment: "Music site intent topic"), "🎵"),
        .init("parenting", NSLocalizedString("Parenting", comment: "Parenting site intent topic"), "👶"),
        .init("people", NSLocalizedString("People", comment: "People site intent topic"), "🧑‍🤝‍🧑"),
        .init("politics", NSLocalizedString("Politics", comment: "Politics site intent topic"), "🗳️"),
        .init("real_estate", NSLocalizedString("Real Estate", comment: "Real Estate site intent topic"), "🏠"),
        .init("sports", NSLocalizedString("Sports", comment: "Sports site intent topic"), "⚽"),
        .init("technology", NSLocalizedString("Technology", comment: "Technology site intent topic"), "💻"),
        .init("writing_poetry", NSLocalizedString("Writing & Poetry", comment: "Writing & Poetry site intent topic"), "📓")
    ]

    static let defaultVerticals: [SiteIntentVertical] = {
        allVerticals.filter { $0.isDefault }
    }()

    // Filters verticals based on search term and appends a custom vertical if there were no exact matches
    static func filterVerticals(with term: String) -> [SiteIntentVertical] {
        guard !term.isEmpty else {
            return allVerticals
        }

        let matchedVerticals = allVerticals.filter { $0.localizedTitle.lowercased().contains(term.lowercased()) }
        let customVertical = customVertical(from: matchedVerticals, term: term)

        return ([customVertical] + matchedVerticals).compactMap { $0 }
    }

    // Returns a custom vertical if there were no exact matches in the supplied array of verticals
    private static func customVertical(from verticals: [SiteIntentVertical], term: String) -> SiteIntentVertical? {
        guard !verticals.contains(where: { $0.localizedTitle.lowercased() == term.lowercased() }) else {
            return nil
        }

        return SiteIntentVertical(
            slug: term.lowercased(),
            localizedTitle: term,
            emoji: "＋",
            isCustom: true
        )
    }
}

fileprivate extension SiteIntentVertical {
    init(_ slug: String,
         _ localizedTitle: String,
         _ emoji: String,
         isDefault: Bool = false,
         isCustom: Bool = false) {

        self.slug = slug
        self.localizedTitle = localizedTitle
        self.emoji = emoji
        self.isDefault = isDefault
        self.isCustom = isCustom
    }
}
