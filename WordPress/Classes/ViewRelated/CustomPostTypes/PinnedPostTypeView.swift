import Foundation
import SwiftUI
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal
import WordPressUI

struct PinnedPostTypeView: View {
    let blog: Blog
    let customPostTypeService: CustomPostTypeService
    let postType: PinnedPostType

    @SiteStorage private var pinnedTypes: [PinnedPostType]

    @State private var service: WpSelfHostedService?
    @State private var details: PostTypeDetailsWithEditContext?
    @State private var isLoading = true
    @State private var error: Error?

    init(blog: Blog, service: CustomPostTypeService, postType: PinnedPostType) {
        self.blog = blog
        self.customPostTypeService = service
        self.postType = postType
        _pinnedTypes = .pinnedPostTypes(for: TaggedManagedObjectID(blog))
    }

    var body: some View {
        Group {
            if let details, let wpService = customPostTypeService.wpService {
                CustomPostTabView(client: customPostTypeService.client, service: wpService, endpoint: details.toPostEndpointType(), details: details, blog: blog)
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
        do {
            service = try await customPostTypeService.client.service

            if let details = try await customPostTypeService.resolvePostType(slug: postType.slug) {
                self.details = details
            } else {
                pinnedTypes.removeAll { $0.slug == postType.slug }
                self.error = PostTypeNotFoundError(name: postType.name)
            }
        } catch {
            DDLogError("Failed to resolve post type '\(postType.slug)': \(error)")
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
    static func pinnedPostTypes(for blog: TaggedManagedObjectID<Blog>) -> Self {
        SiteStorage(wrappedValue: [], "pinned-post-types", blog: blog)
    }
}

extension SiteStorageAccess {
    static func pinnedPostTypes(for blog: TaggedManagedObjectID<Blog>) -> [PinnedPostType] {
        read([PinnedPostType].self, key: "pinned-post-types", blog: blog) ?? []
    }

    static func writePinnedPostTypes(_ value: [PinnedPostType], for blog: TaggedManagedObjectID<Blog>) {
        write(value, key: "pinned-post-types", blog: blog)
    }

    static func pinnedPostTypesUpdated(for blog: TaggedManagedObjectID<Blog>) -> Bool {
        exists(key: "pinned-post-types", blog: blog)
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
