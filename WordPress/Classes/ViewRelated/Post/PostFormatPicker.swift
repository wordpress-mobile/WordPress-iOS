import SwiftUI
import WordPressData
import WordPressFlux
import WordPressUI

@MainActor
struct PostFormatPicker: View {
    @ObservedObject private var post: Post
    @State private var selction: String
    @State private var formats: [String]
    @State private var isLoading = false
    @State private var error: Error?

    private let blog: Blog
    private let onSubmit: (String) -> Void

    static var title: String { Strings.title }

    init(post: Post, onSubmit: @escaping (String) -> Void) {
        self.post = post
        self.blog = post.blog
        let formats = post.blog.sortedPostFormatNames
        self._formats = State(initialValue: formats)
        self._selction = State(initialValue: post.postFormatText() ?? "")
        self.onSubmit = onSubmit
    }

    var body: some View {
        Group {
            if formats.isEmpty {
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
            if formats.isEmpty {
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
            ForEach(formats, id: \.self) { format in
                Button(action: { selectFormat(format) }) {
                    HStack {
                        Text(format)
                        Spacer()
                        if selction == format {
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

    private func selectFormat(_ format: String) {
        selction = format
        onSubmit(format)
    }

    private func refreshPostFormats() async {
        isLoading = true
        error = nil

        let blogService = BlogService(coreDataStack: ContextManager.shared)
        do {
            try await blogService.syncPostFormats(for: post.blog)
            self.formats = post.blog.sortedPostFormatNames
        } catch {
            self.error = error
            if !formats.isEmpty {
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
