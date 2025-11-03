import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import WordPressShared
import WordPressUI

struct SiteCustomTaxonomiesView: View {
    let blog: Blog
    let client: WordPressClient

    @State private var isLoading: Bool = false
    @State private var taxonomies: [SiteTaxonomy]? = nil
    @State private var error: Error?

    init(blog: Blog, client: WordPressClient) {
        self.blog = blog
        self.client = client
    }

    var body: some View {
        List {
            ForEach(taxonomies ?? [], id: \.slug) { taxonomy in
                NavigationLink {
                    SiteTagsView(viewModel: .init(blog: blog, client: client, taxonomy: taxonomy, mode: .browse))
                } label: {
                    Text(taxonomy.localizedName)
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            } else if let taxonomies, taxonomies.isEmpty {
                EmptyStateView(
                    Strings.emptyTitle,
                    systemImage: "archivebox",
                    description: Strings.emptyDescription
                )
            } else if let error {
                EmptyStateView.failure(error: error)
            }
        }
        .navigationTitle(Strings.navigationTitle)
        .task {
            await loadTaxonomies()
        }
    }

    private func loadTaxonomies() async {
        guard taxonomies == nil else { return }

        isLoading = true
        defer { isLoading = false }

        self.error = nil
        do {
            let result = try await client.api.taxonomies.listWithEditContext(params: .init()).data
            // The "Categories" and "Tags" are displayed in its own views. This view only displays custom taxonomies.
            let customTaxonomies: [TaxonomyTypeDetailsWithEditContext] = result.taxonomyTypes.compactMap { (type, taxonomy) in
                switch type {
                case .category, .navMenu, .postTag, .wpPatternCategory:
                    nil
                case .custom:
                    taxonomy
                }
            }
            self.taxonomies = customTaxonomies.map(SiteTaxonomy.init)
        } catch {
            self.error = error
        }
    }
}

private enum Strings {
    static let navigationTitle = NSLocalizedString(
        "siteCustomTaxonomies.navigationTitle",
        value: "Taxonomies",
        comment: "Navigation title for the custom taxonomies screen"
    )

    static let defaultAddNew = NSLocalizedString(
        "siteCustomTaxonomies.defaultAddNew",
        value: "Add",
        comment: "Default text for adding a new item when no label is provided"
    )

    static let emptyTitle = NSLocalizedString(
        "siteCustomTaxonomies.empty.title",
        value: "No custom taxonomies",
        comment: "Title for empty state when there are no custom taxonomies"
    )

    static let emptyDescription = NSLocalizedString(
        "siteCustomTaxonomies.empty.description",
        value: "Taxonomies help you organize content beyond standard categories and tags.",
        comment: "Description for empty state when there are no custom taxonomies"
    )
}
