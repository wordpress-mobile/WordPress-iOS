import UIKit

class BloggingPromptsViewController: UIViewController, NoResultsViewHost {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var filterTabBar: FilterTabBar!

    private var blog: Blog?
    private var prompts: [BloggingPrompt] = [] {
        didSet {
            tableView.reloadData()
            showNoResultsViewIfNeeded()
        }
    }

    private lazy var bloggingPromptsService: BloggingPromptsService? = {
        return BloggingPromptsService(blog: blog)
    }()

    private var isLoading: Bool = false {
        didSet {
            if isLoading != oldValue {
                showNoResultsViewIfNeeded()
            }
        }
    }

    // MARK: - Init

    class func controllerWithBlog(_ blog: Blog) -> BloggingPromptsViewController {
        let controller = BloggingPromptsViewController.loadFromStoryboard()
        controller.blog = blog
        return controller
    }

    class func show(for blog: Blog, from presentingViewController: UIViewController) {
        WPAnalytics.track(.promptsListViewed)
        let controller = BloggingPromptsViewController.controllerWithBlog(blog)
        presentingViewController.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.viewTitle
        configureFilterTabBar()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPrompts()
    }
}

// MARK: - Private Methods

private extension BloggingPromptsViewController {

    func configureTableView() {
        tableView.register(BloggingPromptTableViewCell.defaultNib,
                           forCellReuseIdentifier: BloggingPromptTableViewCell.defaultReuseID)

        tableView.accessibilityIdentifier = "Blogging Prompts List"
        tableView.allowsSelection = FeatureFlag.bloggingPrompts.enabled
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }

    func showNoResultsViewIfNeeded() {
        guard !isLoading else {
            showLoadingView()
            return
        }

        guard prompts.isEmpty else {
            hideNoResults()
            return
        }

        showNoResultsView()
    }

    func showNoResultsView() {
        hideNoResults()
        configureAndDisplayNoResults(on: view,
                                     title: NoResults.emptyTitle,
                                     image: NoResults.imageName)
    }

    func showLoadingView() {
        hideNoResults()
        configureAndDisplayNoResults(on: view,
                                     title: NoResults.loadingTitle,
                                     accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    func showErrorView() {
        hideNoResults()
        configureAndDisplayNoResults(on: view,
                                     title: NoResults.errorTitle,
                                     subtitle: NoResults.errorSubtitle,
                                     image: NoResults.imageName)
    }

    func fetchPrompts() {
        guard let bloggingPromptsService = bloggingPromptsService else {
            DDLogError("Failed creating BloggingPromptsService instance.")
            showErrorView()
            return
        }

        isLoading = true

        bloggingPromptsService.fetchListPrompts(success: { [weak self] (prompts) in
            self?.isLoading = false
            self?.prompts = prompts.sorted(by: { $0.date.compare($1.date) == .orderedDescending })
        }, failure: { [weak self] (error) in
            DDLogError("Failed fetching blogging prompts: \(String(describing: error))")
            self?.isLoading = false
            self?.showErrorView()
        })
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
        return prompts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BloggingPromptTableViewCell.defaultReuseID) as? BloggingPromptTableViewCell,
              let prompt = prompts[safe: indexPath.row] else {
            return UITableViewCell()
        }

        cell.configure(prompt)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard FeatureFlag.bloggingPrompts.enabled,
              let blog,
              let cell = tableView.cellForRow(at: indexPath) as? BloggingPromptTableViewCell,
              let prompt = cell.prompt else {
            return
        }

        let editor = EditPostViewController(blog: blog, prompt: prompt)
        editor.modalPresentationStyle = .fullScreen
        editor.entryPoint = .bloggingPromptsListView
        present(editor, animated: true)
    }

}

// MARK: - Filter Tab Bar Support

private extension BloggingPromptsViewController {

    // For Blogging Prompts V1, there is a single unfiltered prompts list.
    // The expectation is it will be filtered at some point. So the FilterTabBar is hidden instead of removed.
    // To show it, in the storyboard:
    // - Unhide the FilterTabBar.
    // - Remove the tableView top constraint to superview.
    // - Enable the tableView top constraint to the FilterTabBar bottom.

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
    }

}

// MARK: - StoryboardLoadable

extension BloggingPromptsViewController: StoryboardLoadable {
    static var defaultStoryboardName: String {
        return "BloggingPromptsViewController"
    }
}
