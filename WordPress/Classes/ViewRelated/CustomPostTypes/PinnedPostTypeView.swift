import Foundation
import SwiftUI
import UIKit
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal
import WordPressUI

// TODO: Rename PinnedPostTypeView to reflect its broader role as a post type resolver.
struct PinnedPostTypeView<Content: View>: View {
    struct Resolved {
        let wpService: WpService
        let details: PostTypeDetailsWithEditContext
    }

    let blog: Blog
    let customPostTypeService: CustomPostTypeService
    let postType: PinnedPostType
    weak var presentingViewController: UIViewController?
    let content: (Resolved) -> Content

    @SiteStorage private var pinnedTypes: [PinnedPostType]

    @State private var resolved: Resolved?
    @State private var isLoading = true
    @State private var error: Error?

    init(
        blog: Blog,
        service: CustomPostTypeService,
        postType: PinnedPostType,
        presentingViewController: UIViewController? = nil,
        @ViewBuilder content: @escaping (Resolved) -> Content
    ) {
        self.blog = blog
        self.customPostTypeService = service
        self.postType = postType
        self.presentingViewController = presentingViewController
        self.content = content
        _pinnedTypes = .pinnedPostTypes(for: TaggedManagedObjectID(blog))
    }

    var body: some View {
        Group {
            if let resolved {
                content(resolved)
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
            let wpService = try await customPostTypeService.client.service

            if let details = try await customPostTypeService.resolvePostType(slug: postType.slug) {
                resolved = Resolved(wpService: wpService, details: details)
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

extension PinnedPostType {
    // TODO: Ideally use the post type details directly instead of PinnedPostType,
    // once the CPT infrastructure is more mature.
    static let posts = PinnedPostType(slug: "post", name: "Posts", icon: nil)
    static let pages = PinnedPostType(slug: "page", name: "Pages", icon: nil)
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
