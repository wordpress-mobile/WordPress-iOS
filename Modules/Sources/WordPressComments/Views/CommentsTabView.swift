import SwiftUI
import WordPressCore
import WordPressUI

struct CommentsTabView: View {
    @State private var selectedFilter: CommentsListFilter = .all
    @State private var viewModels: [CommentsListFilter: CommentsListViewModel]
    @State private var titleResolver: PostTitleResolver

    /// A tapped row (and, recursively, a parent comment) pushes a detail screen
    /// through it.
    private let router: CommentsDetailRouter

    init(
        service: any CommentsServiceProtocol,
        titleResolver: PostTitleResolver,
        router: CommentsDetailRouter
    ) {
        self.router = router
        _titleResolver = State(initialValue: titleResolver)

        // The All view model is built first so Pending and Approved can seed
        // their first appearance from its loaded items. All is a strict
        // superset of both under the same sort key, so the filtered items are
        // a true prefix of each tab's list. Spam and Trash can't seed: core's
        // status=all excludes them.
        var models: [CommentsListFilter: CommentsListViewModel] = [:]
        let resolve: @MainActor ([CommentListItem]) -> Void = { [titleResolver] items in
            titleResolver.resolve(ids: items.map(\.postID))
        }
        let allViewModel = CommentsListViewModel(
            filter: .all,
            service: service,
            onItemsAppended: resolve
        )
        models[.all] = allViewModel
        for filter in [CommentsListFilter.pending, .approved] {
            let status: CommentListItem.Status = filter == .pending ? .pending : .approved
            models[filter] = CommentsListViewModel(
                filter: filter,
                service: service,
                seedItems: { [weak allViewModel] in
                    guard let allViewModel, allViewModel.hasLoaded else { return [] }
                    return allViewModel.items.filter { $0.status == status }
                },
                onItemsAppended: resolve
            )
        }
        for filter in [CommentsListFilter.spam, .trash] {
            models[filter] = CommentsListViewModel(
                filter: filter,
                service: service,
                onItemsAppended: resolve
            )
        }
        _viewModels = State(initialValue: models)
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            if let viewModel = viewModels[selectedFilter] {
                CommentsListView(
                    viewModel: viewModel,
                    titleResolver: titleResolver,
                    openComment: { router.open(id: $0, seed: $1) }
                )
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tabBar: some View {
        AdaptiveTabBarRepresentable(
            items: CommentsListFilter.allCases,
            selection: $selectedFilter
        )
        .frame(height: AdaptiveTabBar.tabBarHeight)
    }
}

// Private copy of the SwiftUI bridge for WordPressUI's AdaptiveTabBar. The
// original lives private inside CustomPostTabView in the app target; promoting
// a shared public wrapper is deliberately out of M1 scope.
private struct AdaptiveTabBarRepresentable: UIViewRepresentable {
    let items: [CommentsListFilter]
    @Binding var selection: CommentsListFilter

    func makeUIView(context: Context) -> AdaptiveTabBar {
        let tabBar = AdaptiveTabBar()
        tabBar.preferredFont = UIFont.preferredFont(forTextStyle: .subheadline)
        tabBar.items = items
        tabBar.addTarget(
            context.coordinator,
            action: #selector(Coordinator.tabChanged(_:)),
            for: .valueChanged
        )
        return tabBar
    }

    func updateUIView(_ uiView: AdaptiveTabBar, context: Context) {
        if let index = items.firstIndex(of: selection), uiView.selectedIndex != index {
            uiView.setSelectedIndex(index, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: items, selection: $selection)
    }

    final class Coordinator: NSObject {
        let items: [CommentsListFilter]
        @Binding var selection: CommentsListFilter

        init(items: [CommentsListFilter], selection: Binding<CommentsListFilter>) {
            self.items = items
            _selection = selection
        }

        @objc func tabChanged(_ tabBar: AdaptiveTabBar) {
            if items.indices.contains(tabBar.selectedIndex) {
                selection = items[tabBar.selectedIndex]
            }
        }
    }
}
