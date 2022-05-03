import UIKit


class BloggingPromptsViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var filterTabBar: FilterTabBar!

    private var blog: Blog?

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
    }

}

// MARK: - Private Helpers

private extension BloggingPromptsViewController {

    enum Strings {
        static let viewTitle = NSLocalizedString("Prompts", comment: "View title for Blogging Prompts list.")

    }

}

// MARK: - Table Methods

extension BloggingPromptsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: use fetched prompts count.
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: use custom prompt cell.
        return UITableViewCell()
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
        }

}

// MARK: - StoryboardLoadable

extension BloggingPromptsViewController: StoryboardLoadable {
    static var defaultStoryboardName: String {
        return "BloggingPromptsViewController"
    }
}
