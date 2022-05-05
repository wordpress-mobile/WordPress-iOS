import UIKit


class BloggingPromptsViewController: UIViewController, NoResultsViewHost {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var filterTabBar: FilterTabBar!

    private var blog: Blog?

    // TODO: remove when prompts are fetched, use fetched prompts count.
    private var promptCount: Int = 10
    // TODO: set when prompt fetching is added.
    private var isLoading: Bool = false

    // MARK: - Init

    class func controllerWithBlog(_ blog: Blog) -> BloggingPromptsViewController {
        let controller = BloggingPromptsViewController.loadFromStoryboard()
        controller.blog = blog
        return controller
    }

    class func show(for blog: Blog, from presentingViewController: UIViewController) {
        let controller = BloggingPromptsViewController.controllerWithBlog(blog)
        presentingViewController.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.viewTitle
        configureFilterTabBar()
        configureTableView()
        showNoResultsViewIfNeeded()
    }

}

// MARK: - Private Methods

private extension BloggingPromptsViewController {

    func configureTableView() {
        tableView.register(BloggingPromptTableViewCell.defaultNib,
                           forCellReuseIdentifier: BloggingPromptTableViewCell.defaultReuseID)

        tableView.accessibilityIdentifier = "Blogging Prompts List"
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }

    func showNoResultsViewIfNeeded() {
        hideNoResults()

        guard !isLoading else {
            showLoadingView()
            return
        }

        // TODO: use fetched prompts count.
        guard promptCount == 0 else {
            return
        }

        showNoResultsView()
    }

    func showNoResultsView() {
        configureAndDisplayNoResults(on: tableView,
                                     title: NoResults.emptyTitle,
                                     image: NoResults.imageName)
    }

    func showLoadingView() {
        configureAndDisplayNoResults(on: tableView,
                                     title: NoResults.loadingTitle,
                                     accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    func showErrorView() {
        hideNoResults()
        configureAndDisplayNoResults(on: tableView,
                                     title: NoResults.errorTitle,
                                     subtitle: NoResults.errorSubtitle,
                                     image: NoResults.imageName)
    }

    enum Strings {
        static let viewTitle = NSLocalizedString("Prompts", comment: "View title for Blogging Prompts list.")
    }

    enum NoResults {
        static let loadingTitle = NSLocalizedString("Loading prompts...", comment: "Displayed while blogging prompts are being loaded.")
        static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading blogging prompts.")
        static let errorSubtitle = NSLocalizedString("There was an error loading prompts.", comment: "Text displayed when there is a failure loading blogging prompts.")
        static let emptyTitle = NSLocalizedString("No prompts yet", comment: "Title displayed when there are no blogging prompts to display.")
        static let imageName = "wp-illustration-empty-results"
    }

}

// MARK: - Table Methods

extension BloggingPromptsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: use fetched prompts count.
        return promptCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BloggingPromptTableViewCell.defaultReuseID) as? BloggingPromptTableViewCell else {
            return UITableViewCell()
        }

        // TODO: replace answered with BloggingPrompt.
        cell.configure(answered: indexPath.row > 4)
        return cell
    }

}

// MARK: - Filter Tab Bar Support

private extension BloggingPromptsViewController {

    enum PromptFilter: Int, FilterTabBarItem, CaseIterable {
        case all
        case answered
        case notAnswered

        var title: String {
            switch self {
            case .all: return NSLocalizedString("All", comment: "Title of all Blogging Prompts filter.")
            case .answered: return NSLocalizedString("Answered", comment: "Title of answered Blogging Prompts filter.")
            case .notAnswered: return NSLocalizedString("Not Answered", comment: "Title of unanswered Blogging Prompts filter.")
            }
        }
    }

    func configureFilterTabBar() {
        WPStyleGuide.configureFilterTabBar(filterTabBar)
        filterTabBar.items = PromptFilter.allCases
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterTabBar: FilterTabBar) {
        // TODO:
        // - track selected filter changed
        // - refresh view for selected filter
        showNoResultsViewIfNeeded()
    }

}

// MARK: - StoryboardLoadable

extension BloggingPromptsViewController: StoryboardLoadable {
    static var defaultStoryboardName: String {
        return "BloggingPromptsViewController"
    }
}
