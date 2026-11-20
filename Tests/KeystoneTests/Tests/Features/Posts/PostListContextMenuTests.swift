import ObjectiveC
import UIKit
import XCTest
import WordPressData
import WordPressSharedObjC

@testable import WordPress

// A long press asks for a context menu configuration when it starts, and UIKit
// calls the configuration's action provider when it recognizes the press, about
// half a second later. These tests change the list between the two calls, the
// way a sync does.
//
// The tests use XCTest because the list controllers read `ContextManager.shared`,
// and `useAsSharedInstance(untilTestFinished:)` is the existing way to replace it
// for one test.

final class PostListContextMenuTests: CoreDataTestCase {
    private var blog: Blog!
    private var navigationController: PresentationRecorder!
    private var list: PostListViewController!

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)

        blog = BlogBuilder(mainContext).build()
        for day in 1...3 {
            _ = PostBuilder(mainContext, blog: blog)
                .published()
                .withRemote()
                .with(dateCreated: Date(timeIntervalSinceNow: -Double(day) * 86_400))
                .build()
        }
        contextManager.saveContextAndWait(mainContext)
    }

    @MainActor
    func testMenuTargetsPressedPostAfterRowAboveIsRemoved() throws {
        showList()
        let pressedRow = IndexPath(row: 1, section: 0)
        let pressedPost = try post(in: list.tableView, at: pressedRow)
        let configuration = try makeConfiguration(at: pressedRow)

        try delete(post(in: list.tableView, at: IndexPath(row: 0, section: 0)))

        let menu = try XCTUnwrap(ContextMenuRunner.menu(for: configuration))
        try ContextMenuRunner.performAction(titled: "View", in: menu)
        XCTAssertEqual(navigationController.previewedPost, pressedPost)
    }

    @MainActor
    func testNoMenuAfterPressedPostIsRemoved() throws {
        showList()
        let pressedRow = IndexPath(row: 1, section: 0)
        let configuration = try makeConfiguration(at: pressedRow)

        try delete(post(in: list.tableView, at: pressedRow))

        XCTAssertNil(try ContextMenuRunner.menu(for: configuration))
    }

    @MainActor
    func testNoMenuAfterRowsUpToPressedRowAreRemoved() throws {
        showList()
        let pressedRow = IndexPath(row: 2, section: 0)
        let configuration = try makeConfiguration(at: pressedRow)

        try delete(post(in: list.tableView, at: IndexPath(row: 1, section: 0)))
        try delete(post(in: list.tableView, at: IndexPath(row: 1, section: 0)))

        // Reading a row past the end of the fetched results raises an Objective-C
        // exception, the crash reported in Sentry. Catch it so it fails the test.
        var result: Result<UIMenu?, Error> = .success(nil)
        try WPException.objcTry {
            result = Result { try ContextMenuRunner.menu(for: configuration) }
        }
        XCTAssertNil(try result.get())
    }

    @MainActor
    private func showList() {
        list = PostListViewController.controllerWithBlog(blog)
        navigationController = PresentationRecorder(rootViewController: list)
        layOutRows(of: list)
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 3)
    }

    @MainActor
    private func makeConfiguration(at indexPath: IndexPath) throws -> UIContextMenuConfiguration {
        try XCTUnwrap(list.tableView(list.tableView, contextMenuConfigurationForRowAt: indexPath, point: .zero))
    }

    @MainActor
    private func delete(_ post: AbstractPost) {
        mainContext.delete(post)
        contextManager.saveContextAndWait(mainContext)
        list.tableView.layoutIfNeeded()
    }
}

final class PostSearchContextMenuTests: CoreDataTestCase {
    private let postActions = PostActionsSpy()
    private var blog: Blog!
    private var posts: [Post] = []
    private var search: PostSearchViewController!
    private var tableView: UITableView!

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)

        blog = BlogBuilder(mainContext).build()
        posts = (1...3).map { _ in PostBuilder(mainContext, blog: blog).published().withRemote().build() }
        contextManager.saveContextAndWait(mainContext)
    }

    @MainActor
    func testMenuTargetsPressedPostAfterRowAboveIsRemoved() throws {
        try showResults()
        let pressedRow = IndexPath(row: 1, section: PostSearchViewModel.SectionID.posts.rawValue)
        let pressedPost = try post(in: tableView, at: pressedRow)
        let configuration = try makeConfiguration(at: pressedRow)

        try delete(post(in: tableView, at: IndexPath(row: 0, section: pressedRow.section)))

        let menu = try XCTUnwrap(ContextMenuRunner.menu(for: configuration))
        try ContextMenuRunner.performAction(titled: "View", in: menu)
        XCTAssertEqual(postActions.viewedPosts, [pressedPost])
    }

    @MainActor
    func testNoMenuAfterPressedPostIsRemoved() throws {
        try showResults()
        let pressedRow = IndexPath(row: 1, section: PostSearchViewModel.SectionID.posts.rawValue)
        let configuration = try makeConfiguration(at: pressedRow)

        try delete(post(in: tableView, at: pressedRow))

        XCTAssertNil(try ContextMenuRunner.menu(for: configuration))
    }

    @MainActor
    private func showResults() throws {
        let settings = PostListFilterSettings(blog: blog, postType: .post)
        let viewModel = PostSearchViewModel(blog: blog, filters: settings, coreData: contextManager)
        search = PostSearchViewController(viewModel: viewModel)
        search.configure(UISearchController(searchResultsController: nil), postActions)
        layOutRows(of: search)
        tableView = try XCTUnwrap(search.view.subviews.lazy.compactMap { $0 as? UITableView }.first)

        let criteria = PostSearchCriteria(searchTerm: "post", authorID: nil, tag: nil)
        let service = PostSearchService(
            blog: blog,
            settings: settings,
            criteria: criteria,
            coreDataStack: contextManager
        )
        viewModel.service(service, didAppendPosts: posts)
        tableView.layoutIfNeeded()
        XCTAssertEqual(tableView.numberOfRows(inSection: PostSearchViewModel.SectionID.posts.rawValue), 3)
    }

    @MainActor
    private func makeConfiguration(at indexPath: IndexPath) throws -> UIContextMenuConfiguration {
        try XCTUnwrap(search.tableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: .zero))
    }

    @MainActor
    private func delete(_ post: AbstractPost) {
        mainContext.delete(post)
        contextManager.saveContextAndWait(mainContext)
        tableView.layoutIfNeeded()
    }
}

final class PageListContextMenuTests: CoreDataTestCase {
    private let pagesSection = 1
    private var blog: Blog!
    private var navigationController: PresentationRecorder!
    private var list: PageListViewController!

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)

        blog = BlogBuilder(mainContext).build()
        for _ in 1...3 {
            let page = PageBuilder(mainContext).with(status: .publish).withRemote().build()
            page.blog = blog
        }
        contextManager.saveContextAndWait(mainContext)
    }

    @MainActor
    func testMenuTargetsPressedPageAfterRowAboveIsRemoved() throws {
        showList()
        let pressedRow = IndexPath(row: 1, section: pagesSection)
        let pressedPage = try post(in: list.tableView, at: pressedRow)
        let configuration = try makeConfiguration(at: pressedRow)

        try delete(post(in: list.tableView, at: IndexPath(row: 0, section: pagesSection)))

        let menu = try XCTUnwrap(ContextMenuRunner.menu(for: configuration))
        try ContextMenuRunner.performAction(titled: "View", in: menu)
        XCTAssertEqual(navigationController.previewedPost, pressedPage)
    }

    @MainActor
    func testNoMenuAfterPressedPageIsRemoved() throws {
        showList()
        let pressedRow = IndexPath(row: 1, section: pagesSection)
        let configuration = try makeConfiguration(at: pressedRow)

        let pressedPage = try post(in: list.tableView, at: pressedRow)
        mainContext.delete(pressedPage)
        contextManager.saveContextAndWait(mainContext)

        // Before and after the list rebuilds its rows.
        XCTAssertNil(try ContextMenuRunner.menu(for: configuration))
        waitForRowCount(2)
        XCTAssertNil(try ContextMenuRunner.menu(for: configuration))
    }

    @MainActor
    private func showList() {
        list = PageListViewController.controllerWithBlog(blog)
        navigationController = PresentationRecorder(rootViewController: list)
        layOutRows(of: list)
        waitForRowCount(3)
    }

    @MainActor
    private func makeConfiguration(at indexPath: IndexPath) throws -> UIContextMenuConfiguration {
        try XCTUnwrap(list.tableView(list.tableView, contextMenuConfigurationForRowAt: indexPath, point: .zero))
    }

    /// The page list rebuilds its rows in a task after each change.
    @MainActor
    private func delete(_ post: AbstractPost) {
        let expectedCount = list.tableView.numberOfRows(inSection: pagesSection) - 1
        mainContext.delete(post)
        contextManager.saveContextAndWait(mainContext)
        waitForRowCount(expectedCount)
    }

    @MainActor
    private func waitForRowCount(_ count: Int) {
        let rowsLoaded = expectation(
            for: NSPredicate { [list, pagesSection] _, _ in
                list?.tableView.numberOfRows(inSection: pagesSection) == count
            },
            evaluatedWith: nil
        )
        wait(for: [rowsLoaded], timeout: 5)
        list.tableView.layoutIfNeeded()
    }
}

// MARK: - Helpers

/// Gives the list a size so that its rows have cells: the menus anchor to the
/// pressed cell, and `AbstractPostMenuHelper` builds no actions without one.
@MainActor
private func layOutRows(of viewController: UIViewController) {
    viewController.loadViewIfNeeded()
    viewController.view.frame = CGRect(x: 0, y: 0, width: 400, height: 1200)
    viewController.view.layoutIfNeeded()
}

@MainActor
private func post(in tableView: UITableView, at indexPath: IndexPath) throws -> AbstractPost {
    let cell = try XCTUnwrap(tableView.cellForRow(at: indexPath) as? AbstractPostListCell)
    return try XCTUnwrap(cell.post)
}

/// Runs the parts of a context menu that UIKit runs during a long press.
///
/// UIKit has no public API to call a configuration's action provider, to expand a
/// `UIDeferredMenuElement` (which `AbstractPostMenuHelper` uses for its actions),
/// or to run a `UIAction`. These helpers read UIKit's private storage for all three
/// (checked on iOS 27.2). If UIKit changes it, they throw, so a test fails instead
/// of crashing.
@MainActor
private enum ContextMenuRunner {
    struct MissingUIKitInternal: Error, CustomStringConvertible {
        let description: String
    }

    private typealias ActionProvider = @convention(block) ([UIMenuElement]) -> UIMenu?
    private typealias ElementsCompletion = @convention(block) ([UIMenuElement]) -> Void
    private typealias ElementProvider = @convention(block) (@escaping ElementsCompletion) -> Void
    private typealias ActionHandler = @convention(block) (UIAction) -> Void

    static func menu(for configuration: UIContextMenuConfiguration) throws -> UIMenu? {
        let provider: ActionProvider = try block(named: "actionProvider", of: configuration)
        return provider([])
    }

    static func performAction(titled title: String, in menu: UIMenu) throws {
        let action = try XCTUnwrap(actions(in: menu).first { $0.title == title }, "No \"\(title)\" action in the menu")
        let handler: ActionHandler = try block(named: "handler", of: action)
        handler(action)
    }

    private static func actions(in element: UIMenuElement) throws -> [UIAction] {
        switch element {
        case let action as UIAction:
            return [action]
        case let menu as UIMenu:
            return try menu.children.flatMap(actions(in:))
        case let deferred as UIDeferredMenuElement:
            guard let ivar = class_getInstanceVariable(UIDeferredMenuElement.self, "_elementProvider"),
                let wrapper = object_getIvar(deferred, ivar) as? NSObject
            else {
                throw MissingUIKitInternal(description: "UIDeferredMenuElement has no _elementProvider")
            }
            let provider: ElementProvider = try block(named: "_providerBlock", of: wrapper)
            // `AbstractPostMenuHelper` calls the completion synchronously.
            var elements: [UIMenuElement] = []
            provider { elements = $0 }
            return try elements.flatMap(actions(in:))
        default:
            return []
        }
    }

    private static func block<Block>(named key: String, of object: NSObject) throws -> Block {
        guard object.responds(to: NSSelectorFromString(key)), let value = object.value(forKey: key) else {
            throw MissingUIKitInternal(description: "\(type(of: object)) has no \(key)")
        }
        return unsafeBitCast(value as AnyObject, to: Block.self)
    }
}

/// Records the post preview that "View" presents from a post or page list.
private final class PresentationRecorder: UINavigationController {
    private var presentedController: UIViewController?

    var previewedPost: AbstractPost? {
        let navigationController = presentedController as? UINavigationController
        return (navigationController?.viewControllers.first as? PreviewWebKitViewController)?.post
    }

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentedController = viewControllerToPresent
    }
}

private final class PostActionsSpy: InteractivePostViewDelegate {
    private(set) var viewedPosts: [AbstractPost] = []

    func view(_ post: AbstractPost) {
        viewedPosts.append(post)
    }

    func edit(_ post: AbstractPost) {}
    func stats(for post: AbstractPost) {}
    func duplicate(_ post: AbstractPost) {}
    func publish(_ post: AbstractPost) {}
    func trash(_ post: AbstractPost, completion: @escaping () -> Void) {}
    func delete(_ post: AbstractPost, completion: @escaping () -> Void) {}
    func draft(_ post: AbstractPost) {}
    func retry(_ post: AbstractPost) {}
    func share(_ post: AbstractPost, fromView view: UIView) {}
    func blaze(_ post: AbstractPost) {}
    func comments(_ post: AbstractPost) {}
    func showSettings(for post: AbstractPost) {}
}
