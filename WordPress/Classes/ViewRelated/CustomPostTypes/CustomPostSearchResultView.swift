import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData

struct CustomPostSearchResultView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    @Binding var searchText: String
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let blog: Blog

    @State private var finalSearchText = ""

    var body: some View {
        CustomPostListView(
            viewModel: CustomPostListViewModel(
                client: client,
                service: service,
                endpoint: endpoint,
                filter: CustomPostListFilter.default.with(search: finalSearchText),
                blog: blog
            ),
            details: details,
            client: client,
            onSelectPost: onSelectPost,
            mediaHost: MediaHost(blog)
        )
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(100))
                finalSearchText = searchText
            } catch {
                // Do nothing.
            }
        }
    }
}
