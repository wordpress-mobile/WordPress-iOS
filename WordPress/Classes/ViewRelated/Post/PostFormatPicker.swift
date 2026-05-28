import SwiftUI
import WordPressData
import WordPressFlux
import WordPressUI

@MainActor
struct PostFormatPicker: View {
    /// The currently selected format slug.
    @State private var selection: String?
    /// Sorted format slugs.
    @State private var slugs: [String]
    @State private var isLoading = false
    @State private var error: Error?

    private let blog: Blog
    private let onSubmit: (String) -> Void

    static var title: String { Strings.title }

    init(blog: Blog, currentFormat: String?, onSubmit: @escaping (String) -> Void) {
        self.blog = blog
        self._slugs = State(initialValue: blog.sortedPostFormats)
        self._selection = State(initialValue: currentFormat)
        self.onSubmit = onSubmit
    }

    var body: some View {
        Group {
            if slugs.isEmpty {
                if isLoading {
                    ProgressView()
                } else if let error {
                    EmptyStateView.failure(error: error) {
                        refreshPostFormats()
                    }
                } else {
                    emptyStateView
                }
            } else {
                formView
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshPostFormats()
        }
        .onAppear {
            if slugs.isEmpty {
                refreshPostFormats()
            }
        }
    }

    private func refreshPostFormats() {
        Task {
            await refreshPostFormats()
        }
    }

    private var formView: some View {
        Form {
            ForEach(slugs, id: \.self) { slug in
                Button(action: { selectFormat(slug) }) {
                    HStack {
                        Text(blog.postFormatText(fromSlug: slug) ?? slug)
                        Spacer()
                        if selection == slug {
                            Image(systemName: "checkmark")
                                .fontWeight(.medium)
                                .foregroundColor(Color(UIAppColor.primary))
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            Strings.emptyStateTitle,
            systemImage: Strings.emptyStateDescription,
            description: "questionmark.folder"
        )
    }

    private func selectFormat(_ slug: String) {
        selection = slug
        onSubmit(slug)
    }

    private func refreshPostFormats() async {
        isLoading = true
        error = nil

        let blogService = BlogService(coreDataStack: ContextManager.shared)
        do {
            try await blogService.syncPostFormats(for: blog)
            self.slugs = blog.sortedPostFormats
        } catch {
            self.error = error
            if !slugs.isEmpty {
                Notice(error: error, title: Strings.errorTitle).post()
            }
        }

        isLoading = false
    }
}

private extension BlogService {
    @MainActor func syncPostFormats(for blog: Blog) async throws {
        try await withUnsafeThrowingContinuation { continuation in
            syncPostFormats(for: blog, success: {
                continuation.resume()
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "postFormatPicker.navigationTitle",
        value: "Post Format",
        comment: "Navigation bar title for the Post Format picker"
    )

    static let emptyStateTitle = NSLocalizedString(
        "postFormatPicker.emptyState.title",
        value: "No Post Formats Available",
        comment: "Empty state title when no post formats are available"
    )

    static let emptyStateDescription = NSLocalizedString(
        "postFormatPicker.emptyState.description",
        value: "Post formats haven't been configured for this site.",
        comment: "Empty state description when no post formats are available"
    )

    static let errorTitle = NSLocalizedString(
        "postFormatPicker.refreshErrorMessage",
        value: "Failed to refresh post formats",
        comment: "Error message when post formats refresh fails"
    )
}
