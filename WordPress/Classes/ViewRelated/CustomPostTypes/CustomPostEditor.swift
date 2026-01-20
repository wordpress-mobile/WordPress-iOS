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
            defer { SVProgressHUD.dismiss(withDelay: 0.3) }

            do {
                guard let (title, content) = try await coordinator.getContent() else { return }

                try await update(post: post, title: title, content: content)

                if let image = UIImage(systemName: "checkmark") {
                    SVProgressHUD.show(image, status: nil)
                }

                dismiss()
                success()
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }

    private func update(post: AnyPostWithEditContext, title: String, content: String) async throws {
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
