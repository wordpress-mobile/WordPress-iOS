import SwiftUI

/// Keeps browsing alive so dismissing search restores the selected tab and position.
struct CommentsView: View {
    @ObservedObject var search: CommentsSearchViewModel
    let viewModels: [CommentsListFilter: CommentsListViewModel]
    let titleResolver: PostTitleResolver
    let router: CommentsDetailRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isSearching = false
    @State private var text = ""

    var body: some View {
        ZStack {
            CommentsTabView(
                viewModels: viewModels,
                titleResolver: titleResolver,
                router: router
            )
            .opacity(isSearching ? 0 : 1)
            .allowsHitTesting(!isSearching)
            .accessibilityHidden(isSearching)

            if isSearching {
                CommentsSearchView(
                    viewModel: search,
                    titleResolver: titleResolver,
                    openComment: { router.open(id: $0, seed: $1) }
                )
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $text,
            isPresented: $isSearching,
            placement: searchPlacement,
            prompt: Strings.Search.prompt
        )
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search) {
            Task { await search.submit(text) }
        }
        .onChange(of: isSearching) { _, active in
            if !active {
                text = ""
                search.cancel()
            }
        }
    }

    private var searchPlacement: SearchFieldPlacement {
        // Drawer search overlaps the title on iOS 26; compact toolbar search is missing on iOS 27.
        if #unavailable(iOS 27) {
            if #available(iOS 26, *) {
                return .toolbar
            }
        }
        return horizontalSizeClass == .regular ? .toolbar : .navigationBarDrawer(displayMode: .always)
    }
}
