import Testing
import WordPressData

@testable import WordPress

@MainActor
struct BlogDetailsTableViewModelTests {
    @Test func selectingAnotherPinnedTypeOpensItsDestination() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let controller = BlogDetailsViewController(blog: blog)
        controller.isSidebarModeEnabled = true
        let model = BlogDetailsTableViewModel(blog: blog, viewController: controller)
        var opened: [String] = []
        let books = BlogDetailsTableViewModel.Row(
            kind: .pinnedPostType,
            id: .pinnedPostType("books"),
            title: "Books",
            image: nil,
            action: { _ in opened.append("books") }
        )
        let films = BlogDetailsTableViewModel.Row(
            kind: .pinnedPostType,
            id: .pinnedPostType("films"),
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
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let controller = BlogDetailsViewController(blog: blog)
        controller.isSidebarModeEnabled = true
        let model = BlogDetailsTableViewModel(blog: blog, viewController: controller)
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
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let controller = BlogDetailsViewController(blog: blog)
        let model = BlogDetailsTableViewModel(blog: blog, viewController: controller)
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
}
