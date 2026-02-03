import Foundation
import SwiftUI
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal
import WordPressUI

struct CustomPostTypesView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let blog: Blog

    let collection: PostTypeCollectionWithEditContext

    @State private var types: [(PostEndpointType, PostTypeDetailsWithEditContext)] = []
    @State private var isLoading: Bool = true
    @State private var error: Error?

    init(client: WordPressClient, service: WpSelfHostedService, blog: Blog) {
        self.client = client
        self.service = service
        self.blog = blog
        self.collection = service.postTypes().createPostTypeCollectionWithEditContext()
    }

    var body: some View {
        List {
            ForEach(types, id: \.1.slug) { (type, details) in
                NavigationLink {
                    CustomPostMainView(client: client, service: service, endpoint: type, details: details, blog: blog)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(details.name)

                        if !details.description.isEmpty {
                            Text(details.description)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(Strings.title)
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if let error {
                EmptyStateView.failure(error: error)
            } else if types.isEmpty {
                EmptyStateView(Strings.emptyState, systemImage: "doc.text")
            }
        }
        .task {
            await refresh()

            isLoading = self.types.isEmpty
            defer { isLoading = false }

            do {
                _ = try await self.collection.fetch()
                await refresh()
            } catch {
                self.error = error
            }
        }
    }

    private func refresh() async {
        do {
            self.types = try await self.collection.loadData()
                .compactMap {
                    let details = $0.data
                    let endpoint = details.toPostEndpointType()
                    if case .custom = endpoint, details.slug != "attachment" {
                        return (endpoint, details)
                    }
                    return nil
                }
                .sorted {
                    $0.1.slug < $1.1.slug
                }
        } catch {
            self.error = error
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "customPostTypes.title",
        value: "Custom Post Types",
        comment: "Title for the Custom Post Types screen"
    )

    static let emptyState = NSLocalizedString(
        "customPostTypes.emptyState.message",
        value: "No Custom Post Types",
        comment: "Empty state message when there are no custom post types to display"
    )
}
