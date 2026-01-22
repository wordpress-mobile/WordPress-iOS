import SwiftUI
import SVProgressHUD
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

struct CustomPostEditor: View {
    let client: WordPressClient
    let post: AnyPostWithEditContext
    let details: PostTypeDetailsWithEditContext
    let blog: Blog
    let success: () -> Void

    private let coordinator = SimpleGBKEditor.EditorCoordinator()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SimpleGBKEditor(post: post, blog: blog, coordinator: coordinator)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(SharedStrings.Button.save) {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        Task {
            SVProgressHUD.show()

            do {
                guard let (title, content) = try await coordinator.getContent() else { return }

                try await update(title: title, content: content)
                SVProgressHUD.showSuccess(withStatus: nil)

                dismiss()
                success()
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }

    private func hasBeenModified() async throws -> Bool {
        let endpoint = postTypeDetailsToPostEndpointType(postTypeDetails: details)
        let lastModified = try await client.api.posts
            .filterRetrieveWithEditContext(
                postEndpointType: endpoint,
                postId: post.id,
                params: .init(),
                fields: [.modified]
            )
            .data
            .modified
        return lastModified != post.modified
    }

    private func update(title: String, content: String) async throws {
        // This is a simple way to avoid overwriting others' changes. We can further improve it
        // to align with the implementation in `PostRepository`.
        guard try await !hasBeenModified() else { throw PostUpdateError.conflicts }

        let hasTitle = details.supports.map[.title] == .bool(true)
        let params = PostUpdateParams(
            title: hasTitle ? title : nil,
            content: content,
            meta: nil
        )
        _ = try await client.api
            .posts
            .update(
                postEndpointType: postTypeDetailsToPostEndpointType(postTypeDetails: details),
                postId: post.id,
                params: params
            )
    }
}

private struct SimpleGBKEditor: UIViewControllerRepresentable {
    class EditorCoordinator {
        weak var editor: SimpleGBKViewController?

        func getContent() async throws -> (title: String, content: String)? {
            try await editor?.getCurrentContent()
        }
    }

    let post: AnyPostWithEditContext
    let blog: Blog
    let coordinator: EditorCoordinator

    func makeCoordinator() -> EditorCoordinator {
        coordinator
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let editor = SimpleGBKViewController(
            postID: Int(post.id),
            postTitle: post.title?.raw,
            content: post.content.raw ?? "",
            blog: blog,
            postType: post.postType
        )
        context.coordinator.editor = editor
        return editor
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

private enum PostUpdateError: LocalizedError {
    case conflicts

    var errorDescription: String? {
        Strings.conflictErrorMessage
    }
}

private enum Strings {
    static let conflictErrorMessage = NSLocalizedString(
        "customPostEditor.error.conflict.message",
        value: "The post you are trying to save has been changed in the meantime.",
        comment: "Error message shown when the post was modified by another user while editing"
    )
}
