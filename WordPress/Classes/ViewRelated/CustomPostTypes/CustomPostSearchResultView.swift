import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

struct CustomPostSearchResultView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    @Binding var searchText: String
    let onSelectPost: (AnyPostWithEditContext) -> Void

    @State private var finalSearchText = ""

    var body: some View {
        CustomPostListView(
            viewModel: CustomPostListViewModel(
                client: client,
                service: service,
                endpoint: endpoint,
                filter: CustomPostListFilter.default.with(search: finalSearchText)
            ),
            details: details,
            onSelectPost: onSelectPost
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
