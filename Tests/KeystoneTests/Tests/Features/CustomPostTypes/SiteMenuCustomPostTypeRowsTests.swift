import Testing
import UIKit
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Site menu custom post type rows")
struct SiteMenuCustomPostTypeRowsTests {
    private let contextManager = ContextManager.forTesting()
    private let blog: Blog
    private let viewController: BlogDetailsViewController

    init() {
        blog = BlogBuilder(contextManager.mainContext).with(isAdmin: true).build()
        viewController = BlogDetailsViewController(blog: blog)
    }

    @Test("appends one row per custom post type after Comments", arguments: [true, false])
    func appendsRowsAfterComments(usesWordPressLayout: Bool) throws {
        let types = [
            PostTypeDetailsWithEditContext.fixture(slug: "book", name: "Books"),
            PostTypeDetailsWithEditContext.fixture(slug: "movie", name: "Movies")
        ]
        let viewModel = makeViewModel(usesWordPressLayout: usesWordPressLayout)
        viewModel.customPostTypes = types
        viewModel.configureTableViewData()

        let rows = try #require(viewModel.sections.first { $0.category == .content }).rows
        let comments = try #require(rows.firstIndex { $0.kind == .comments })
        #expect(rows.count == comments + 1 + types.count)

        for (offset, type) in types.enumerated() {
            let row = rows[comments + 1 + offset]
            #expect(row.kind == .customPostType(slug: type.slug))
            #expect(row.id == .row(.customPostType(slug: type.slug)))
            #expect(row.title == type.name)
        }
    }

    @Test("keeps the built-in rows in place", arguments: [true, false])
    func keepsBuiltInRowsInPlace(usesWordPressLayout: Bool) throws {
        let builtInRows: [BlogDetailsRowKind] = [.posts, .pages, .media, .comments]
        let viewModel = makeViewModel(usesWordPressLayout: usesWordPressLayout)

        viewModel.configureTableViewData()
        let positionsWithoutCustomTypes = builtInRows.map { indexPath(for: $0, in: viewModel) }
        #expect(!positionsWithoutCustomTypes.contains(nil))
        let comments = try #require(indexPath(for: .comments, in: viewModel))
        #expect(viewModel.sections[comments.section].rows.count == comments.row + 1)

        viewModel.customPostTypes = [.fixture(slug: "book", name: "Books")]
        viewModel.configureTableViewData()
        #expect(builtInRows.map { indexPath(for: $0, in: viewModel) } == positionsWithoutCustomTypes)
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

        let viewModel = makeViewModel(usesWordPressLayout: false)
        viewModel.customPostTypes = types
        viewModel.configureTableViewData()
        viewModel.showDetailView(for: .customPostType(slug: "movie"))
        let selected = try #require(viewModel.selectedRowID)
        #expect(selected == .row(.customPostType(slug: "movie")))
        #expect(presenter.presentedCount == 1)

        viewModel.customPostTypes = [types[1], types[2]]
        viewModel.configureTableViewData()

        #expect(viewModel.selectedRowID == selected)
        #expect(presenter.presentedCount == 1)
    }

    private func makeViewModel(usesWordPressLayout: Bool) -> BlogDetailsTableViewModel {
        BlogDetailsTableViewModel(
            blog: blog,
            viewController: viewController,
            usesWordPressLayout: usesWordPressLayout,
            makeCustomPostTypeService: { _ in nil }
        )
    }

    private func indexPath(for kind: BlogDetailsRowKind, in viewModel: BlogDetailsTableViewModel) -> IndexPath? {
        for (sectionIndex, section) in viewModel.sections.enumerated() {
            if let rowIndex = section.rows.firstIndex(where: { $0.kind == kind }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
}

private final class PresentationRecorder: BlogDetailsPresentationDelegate {
    private(set) var presentedCount = 0

    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        presentedCount += 1
    }
}
