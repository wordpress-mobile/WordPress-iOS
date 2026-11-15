import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import WordPressUI

struct PostTypeResolverView<Content: View>: View {
    struct Resolved {
        let wpService: WpService
        let details: PostTypeDetailsWithEditContext
    }

    let customPostTypeService: CustomPostTypeService
    let postType: PostTypeReference
    let content: (Resolved) -> Content

    @State private var resolved: Resolved?
    @State private var isLoading = true
    @State private var error: Error?

    init(
        service: CustomPostTypeService,
        postType: PostTypeReference,
        @ViewBuilder content: @escaping (Resolved) -> Content
    ) {
        self.customPostTypeService = service
        self.postType = postType
        self.content = content
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

            switch postType {
            case .details(let details):
                resolved = Resolved(wpService: wpService, details: details)
            case .slug(let slug):
                if let details = try await customPostTypeService.resolvePostType(slug: slug) {
                    resolved = Resolved(wpService: wpService, details: details)
                } else {
                    self.error = PostTypeNotFoundError(slug: slug)
                }
            }
        } catch {
            Loggers.app.error("Failed to resolve post type: \(error)")
            self.error = error
        }
    }
}

enum PostTypeReference {
    /// Looked up in the cache, falling back to syncing the site's post types when it is missing.
    case slug(String)
    case details(PostTypeDetailsWithEditContext)

    static let post = PostTypeReference.slug("post")
    static let page = PostTypeReference.slug("page")
}

private struct PostTypeNotFoundError: LocalizedError {
    let slug: String

    var errorDescription: String? {
        String.localizedStringWithFormat(Strings.notFound, slug)
    }
}

private enum Strings {
    static let notFound = NSLocalizedString(
        "pinnedPostType.error.notFound",
        value: "\"%1$@\" is not available on this site.",
        comment: "Error message when a post type cannot be found on the site. %1$@ is the post type slug, e.g. 'post'."
    )
}
