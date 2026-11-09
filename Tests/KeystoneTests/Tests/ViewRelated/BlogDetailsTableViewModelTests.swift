import Testing
import UIKit
import WordPressData

@testable import WordPress

@MainActor
struct BlogDetailsTableViewModelTests {
    @Test func selectingAnotherCustomTypeOpensItsDestination() {
        let contextManager = ContextManager.forTesting()
        let context = contextManager.mainContext
        let blog = BlogBuilder(context).build()
        let controller = BlogDetailsViewController(blog: blog)
        controller.isSidebarModeEnabled = true
        let model = BlogDetailsTableViewModel(
            blog: blog,
            viewController: controller,
            makeCustomPostTypeService: { _ in nil }
        )
        var opened: [String] = []
        let books = BlogDetailsTableViewModel.Row(
            kind: .customPostType(slug: "books"),
            title: "Books",
            image: nil,
            action: { _ in opened.append("books") }
        )
        let films = BlogDetailsTableViewModel.Row(
            kind: .customPostType(slug: "films"),
            title: "Films",
            image: nil,
            action: { _ in opened.append("films") }
        )

        model.select(books)
        model.select(films)
        model.select(films)

        #expect(opened == ["books", "films"])
        #expect(model.selectedRowID == films.id)
    }

    @Test func externalActionPreservesSidebarSelection() {
        let contextManager = ContextManager.forTesting()
        let context = contextManager.mainContext
        let blog = BlogBuilder(context).build()
        let controller = BlogDetailsViewController(blog: blog)
        controller.isSidebarModeEnabled = true
        let model = BlogDetailsTableViewModel(
            blog: blog,
            viewController: controller,
            makeCustomPostTypeService: { _ in nil }
        )
        var externalOpenCount = 0
        let posts = BlogDetailsTableViewModel.Row(kind: .posts, title: "Posts", image: nil)
        let external = BlogDetailsTableViewModel.Row(
            kind: .viewSite,
            title: "View Site",
            image: nil,
            showsSelectionState: false,
            action: { _ in externalOpenCount += 1 }
        )

        model.select(posts)
        model.select(external)
        model.select(external)

        #expect(externalOpenCount == 2)
        #expect(model.selectedRowID == posts.id)
    }

    @Test func returningToPhoneMenuAllowsReopeningTheSameDestination() {
        let contextManager = ContextManager.forTesting()
        let context = contextManager.mainContext
        let blog = BlogBuilder(context).build()
        let controller = BlogDetailsViewController(blog: blog)
        let model = BlogDetailsTableViewModel(
            blog: blog,
            viewController: controller,
            makeCustomPostTypeService: { _ in nil }
        )
        var openCount = 0
        let posts = BlogDetailsTableViewModel.Row(
            kind: .posts,
            title: "Posts",
            image: nil,
            action: { _ in openCount += 1 }
        )

        model.select(posts)
        model.viewWillAppear()
        #expect(model.selectedRowID == nil)
        model.select(posts)

        #expect(openCount == 2)
    }

    @Test func opensTheDefaultDestinationWhenItsRowAppears() throws {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).with(isAdmin: true).build()
        let controller = BlogDetailsViewController(blog: blog)
        controller.isSidebarModeEnabled = true
        let presenter = DefaultDestinationRecorder()
        controller.presentationDelegate = presenter
        let model = BlogDetailsTableViewModel(
            blog: blog,
            viewController: controller,
            makeCustomPostTypeService: { _ in nil }
        )
        let destination = model.defaultSubsection()

        model.showInitialDetailsForBlog()
        #expect(model.sections.isEmpty)
        #expect(presenter.presentedCount == 0)

        model.configureTableViewData()

        _ = try #require(model.sections.flatMap(\.rows).first { $0.kind == destination })
        #expect(model.selectedRowID == .row(destination))
        #expect(presenter.presentedCount == 1)

        model.configureTableViewData()
        #expect(presenter.presentedCount == 1)
    }

    @Test func selectingARowCancelsThePendingDefaultDestination() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).with(isAdmin: true).build()
        let controller = BlogDetailsViewController(blog: blog)
        controller.isSidebarModeEnabled = true
        let presenter = DefaultDestinationRecorder()
        controller.presentationDelegate = presenter
        let model = BlogDetailsTableViewModel(
            blog: blog,
            viewController: controller,
            makeCustomPostTypeService: { _ in nil }
        )

        model.showInitialDetailsForBlog()
        model.select(.init(kind: .comments, title: "Comments", image: nil))
        model.configureTableViewData()

        #expect(model.selectedRowID == .row(.comments))
        #expect(presenter.presentedCount == 0)
    }

    @Test func changingSitesCancelsThePendingDefaultDestination() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).with(isAdmin: true).build()
        let controller = BlogDetailsViewController(blog: blog)
        controller.isSidebarModeEnabled = true
        let presenter = DefaultDestinationRecorder()
        controller.presentationDelegate = presenter
        let model = BlogDetailsTableViewModel(
            blog: blog,
            viewController: controller,
            makeCustomPostTypeService: { _ in nil }
        )

        model.showInitialDetailsForBlog()
        model.blog = BlogBuilder(contextManager.mainContext).with(isAdmin: true).build()

        #expect(model.selectedRowID == nil)
        #expect(presenter.presentedCount == 0)
    }
}

private final class DefaultDestinationRecorder: BlogDetailsPresentationDelegate {
    private(set) var presentedCount = 0

    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        presentedCount += 1
    }
}
