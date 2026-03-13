import Foundation
import SwiftUI
import UIKit
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData

struct CustomPostSearchResultView: View {
    let blog: Blog
    let client: WordPressClient
    let service: WpService
    let details: PostTypeDetailsWithEditContext
    @Binding var searchText: String
    weak var presentingViewController: UIViewController?
    let onSelectPost: (AnyPostWithEditContext) -> Void

    @State private var finalSearchText = ""

    var body: some View {
        CustomPostListView(
            viewModel: CustomPostListViewModel(
                client: client,
                service: service,
                details: details,
                filter: .search(input: finalSearchText),
                blog: blog,
                presentingViewController: presentingViewController
            ),
            details: details,
            client: client,
            mediaHost: MediaHost(blog),
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
