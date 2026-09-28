import Testing
import UIKit
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Site menu custom post type rows")
struct SiteMenuCustomPostTypeRowsTests {
    private let blog: Blog
    private let viewController: BlogDetailsViewController

    init() {
        let contextManager = ContextManager.forTesting()
        blog = BlogBuilder(contextManager.mainContext).build()
        viewController = BlogDetailsViewController(blog: blog)
    }

    @Test("appends one row per custom post type after Comments", arguments: [true, false])
    func appendsRowsAfterComments(usesWordPressLayout: Bool) throws {
        let types = [
            PostTypeDetailsWithEditContext.fixture(slug: "book", name: "Books"),
            PostTypeDetailsWithEditContext.fixture(slug: "movie", name: "Movies")
        ]
        let (viewModel, tableView) = makeViewModel(usesWordPressLayout: usesWordPressLayout)
        viewModel.customPostTypes = types
        viewModel.configureTableViewData()

        let comments = try #require(viewModel.indexPath(for: .comments))
        #expect(
            viewModel.tableView(tableView, numberOfRowsInSection: comments.section) == comments.row + 1 + types.count
        )

        for (offset, type) in types.enumerated() {
            let indexPath = IndexPath(row: comments.row + 1 + offset, section: comments.section)
            #expect(viewModel.indexPath(for: .customPostType(slug: type.slug)) == indexPath)
            #expect(viewModel.tableView(tableView, cellForRowAt: indexPath).textLabel?.text == type.name)
        }
    }

    @Test("keeps the built-in rows in place", arguments: [true, false])
    func keepsBuiltInRowsInPlace(usesWordPressLayout: Bool) throws {
        let builtInRows: [BlogDetailsRowKind] = [.posts, .pages, .media, .comments]
        let (viewModel, tableView) = makeViewModel(usesWordPressLayout: usesWordPressLayout)

        viewModel.configureTableViewData()
        let positionsWithoutCustomTypes = builtInRows.map(viewModel.indexPath(for:))
        let comments = try #require(viewModel.indexPath(for: .comments))
        #expect(viewModel.tableView(tableView, numberOfRowsInSection: comments.section) == comments.row + 1)

        viewModel.customPostTypes = [.fixture(slug: "book", name: "Books")]
        viewModel.configureTableViewData()
        #expect(builtInRows.map(viewModel.indexPath(for:)) == positionsWithoutCustomTypes)
    }

    @Test("keeps the selected custom post type selected after a rebuild")
    func keepsSelectedCustomPostTypeAfterRebuild() throws {
        let types: [PostTypeDetailsWithEditContext] = [
            .fixture(slug: "book", name: "Books"),
            .fixture(slug: "movie", name: "Movies"),
            .fixture(slug: "song", name: "Songs")
        ]
        let presenter = PresentationRecorder()
        viewController.isSidebarModeEnabled = true
        viewController.presentationDelegate = presenter

        let (viewModel, tableView) = makeViewModel(usesWordPressLayout: false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 2000))
        window.addSubview(tableView)
        tableView.frame = window.bounds
        defer { tableView.removeFromSuperview() }

        viewModel.customPostTypes = types
        viewModel.configureTableViewData()
        tableView.reloadData()
        viewModel.showDetailView(for: .customPostType(slug: "movie"))
        let selected = try #require(viewModel.indexPath(for: .customPostType(slug: "movie")))
        #expect(tableView.indexPathForSelectedRow == selected)
        #expect(presenter.presentedCount == 1)

        viewModel.configureTableViewData()
        viewModel.reloadTableViewPreservingSelection()

        #expect(tableView.indexPathForSelectedRow == selected)
        #expect(presenter.presentedCount == 1)
    }

    private func makeViewModel(usesWordPressLayout: Bool) -> (BlogDetailsTableViewModel, UITableView) {
        let viewModel = BlogDetailsTableViewModel(
            blog: blog,
            viewController: viewController,
            usesWordPressLayout: usesWordPressLayout,
            makeCustomPostTypeService: { _ in nil }
        )
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 400, height: 2000), style: .grouped)
        viewModel.configure(tableView: tableView)
        return (viewModel, tableView)
    }
}

private final class PresentationRecorder: BlogDetailsPresentationDelegate {
    private(set) var presentedCount = 0

    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        presentedCount += 1
    }
}
