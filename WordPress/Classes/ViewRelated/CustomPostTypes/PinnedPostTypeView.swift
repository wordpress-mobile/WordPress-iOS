import Foundation
import SwiftUI
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal
import WordPressUI

struct PinnedPostTypeView: View {
    let client: WordPressClient
    let blog: Blog
    let postType: PinnedPostType

    @SiteStorage private var pinnedTypes: [PinnedPostType]

    @State private var resolved: (WpSelfHostedService, PostTypeDetailsWithEditContext)?
    @State private var isLoading = true
    @State private var error: Error?

    init(client: WordPressClient, blog: Blog, postType: PinnedPostType) {
        self.client = client
        self.blog = blog
        self.postType = postType
        _pinnedTypes = .pinnedPostTypes(for: blog)
    }

    var body: some View {
        Group {
            if let (service, details) = resolved {
                CustomPostTabView(client: client, service: service, endpoint: details.toPostEndpointType(), details: details, blog: blog)
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if let error {
                EmptyStateView.failure(error: error, onRetry: error is PostTypeNotFoundError ? nil : { retry() })
            }
        }
        .task {
            await resolve()
        }
    }

    private func retry() {
        error = nil
        isLoading = true
        Task {
            await resolve()
        }
    }

    private func resolve() async {
        defer { isLoading = false }

        let slug = postType.slug

        do {
            let service = try await client.service
            let postTypes = service.postTypes()

            if let details = postTypes.getBySlug(slug: slug) {
                resolved = (service, details)
                return
            }

            _ = try await postTypes.syncPostTypes()

            if let details = postTypes.getBySlug(slug: slug) {
                resolved = (service, details)
            } else {
                pinnedTypes.removeAll { $0.slug == slug }
                self.error = PostTypeNotFoundError(name: postType.name)
            }
        } catch {
            DDLogError("Failed to resolve post type '\(slug)': \(error)")
            self.error = error
        }
    }
}

struct PinnedPostType: Codable, Hashable {
    let slug: String
    let name: String
    let icon: String?
}

extension SiteStorage where Value == [PinnedPostType] {
    static func pinnedPostTypes(for blog: Blog) -> Self {
        SiteStorage(wrappedValue: [], "pinned-post-types", blog: TaggedManagedObjectID(blog))
    }
}

extension SiteStorageReader {
    static func pinnedPostTypes(for blog: Blog) -> [PinnedPostType] {
        read([PinnedPostType].self, key: "pinned-post-types", blog: blog) ?? []
    }
}

private struct PostTypeNotFoundError: LocalizedError {
    let name: String

    var errorDescription: String? {
        String.localizedStringWithFormat(Strings.notFound, name)
    }
}

private enum Strings {
    static let notFound = NSLocalizedString(
        "pinnedPostType.error.notFound",
        value: "\"%1$@\" is not available on this site.",
        comment: "Error message when a pinned custom post type cannot be found. %1$@ is the post type name."
    )
}
