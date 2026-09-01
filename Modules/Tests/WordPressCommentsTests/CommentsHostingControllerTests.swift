import SwiftUI
import Testing
@testable import WordPressComments

@MainActor
struct CommentsHostingControllerTests {
    @Test func viewWillAppearReloadsOnlyTabsAwaitingStaleReload() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let staleTab = CommentsListViewModel(filter: .all, service: service)
        await staleTab.onAppear()
        // A change event stales the tab and its eager reload fails while the
        // list is off screen.
        staleTab.apply(.statusChanged(id: 99, to: .pending))
        await staleTab.onAppear()
        #expect(staleTab.state == .awaitingReload)
        let neverLoadedTab = CommentsListViewModel(filter: .pending, service: service)

        let controller = CommentsRootHostingController(
            rootView: EmptyView(),
            listViewModels: [staleTab, neverLoadedTab]
        )
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        await waitUntil { staleTab.state == .loaded }

        #expect(staleTab.items.map(\.id) == [2])
        // The never-loaded tab is left to its own first appearance.
        #expect(service.requests.map(\.filter) == [.all, .all, .all])
    }
}
