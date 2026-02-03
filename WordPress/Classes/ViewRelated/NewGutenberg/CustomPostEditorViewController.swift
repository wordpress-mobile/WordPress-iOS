import Foundation
import UIKit
import SafariServices
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData
import SVProgressHUD
import GutenbergKit

class CustomPostEditorViewController: PostGBKEditorViewController {
    let client: WordPressClient
    let post: AnyPostWithEditContext
    let details: PostTypeDetailsWithEditContext
    let success: () -> Void

    init(
        blog: Blog,
        client: WordPressClient,
        post: AnyPostWithEditContext,
        details: PostTypeDetailsWithEditContext,
        success: @escaping () -> Void
    ) {
        self.client = client
        self.post = post
        self.details = details
        self.success = success

        super.init(
            postId: Int(post.id),
            postType: post.postType,
            title: post.title?.raw,
            content: post.content.raw,
            status: post.status.stringValue(),
            blog: blog
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var publishButtonText: String {
        return "Save"
    }

    override var isPublishButtonEnabled: Bool {
         return true
    }

    override var uploadingButtonSize: CGSize {
        return AztecPostViewController.Constants.uploadingButtonSize
    }

    override func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        // TODO: Show alert
        dismiss(animated: true)
    }

    override func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        Task {
            await self.save()
        }
    }

    override func makeMoreMenu() -> UIMenu {
        UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
            UIDeferredMenuElement.uncached { [weak self] callback in
                // Common actions at the top so they are always in the same
                // relative place.
                callback(self?.makeMoreMenuMainSections() ?? [])
            },
            UIDeferredMenuElement.uncached { [weak self] callback in
                // Dynamic actions at the bottom. The actions are loaded asynchronously
                // because they need the latest post content from the editor
                // to display the correct state.
                Task {
                    let data = try await self?.getTitleAndContent()
                    if let self, let data {
                        callback(self.makeMoreMenuAsyncSections(data: data))
                    }
                }
            }
        ])
    }

    private func makeMoreMenuMainSections() -> [UIMenuElement] {
        return  [
            UIMenu(title: "", subtitle: "", options: .displayInline, children: makeMoreMenuActions()),
        ]
    }

    private func makeMoreMenuAsyncSections(data: GutenbergKit.EditorViewController.EditorTitleAndContent) -> [UIMenuElement] {
        [
            // Dynamic actions at the bottom
            UIMenu(title: "", subtitle: "", options: .displayInline, children: makeMoreMenuSecondaryActions(data: data))
        ]
    }

    private func makeMoreMenuSecondaryActions(data: GutenbergKit.EditorViewController.EditorTitleAndContent) -> [UIAction] {
        var actions: [UIAction] = []
        if post.status == .draft {
            actions.append(UIAction(title: Strings.saveDraft, image: UIImage(systemName: "doc"), attributes: (data.changed && data.title != "" && data.content != "") ? [] : [.disabled]) { [weak self] _ in
                Task {
                    await self?.save()
                }
            })
        }
        return actions
    }

    private func makeMoreMenuActions() -> [UIAction] {
        var actions: [UIAction] = []

        let toggleModeTitle = editorViewController.isCodeEditorEnabled ? Strings.visualEditor : Strings.codeEditor
        let toggleModeIconName = editorViewController.isCodeEditorEnabled ? "doc.richtext" : "curlybraces"
        actions.append(UIAction(title: toggleModeTitle, image: UIImage(systemName: toggleModeIconName)) { [weak self] _ in
            self?.toggleEditingMode()
        })

        let helpTitle = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() ? Strings.helpAndSupport : Strings.help
        actions.append(UIAction(title: helpTitle, image: UIImage(systemName: "questionmark.circle")) { [weak self] _ in
            self?.showEditorHelp()
        })
        actions.append(UIAction(title: Strings.sendFeedback, image: UIImage(systemName: "envelope")) { [weak self] _ in
            self?.showFeedbackView()
        })
        return actions
    }

    private func save() async {
        SVProgressHUD.show()

        do {
            let data = try await editorViewController.getTitleAndContent()

            try await update(title: data.title, content: data.content)
            SVProgressHUD.showSuccess(withStatus: nil)

            success()
        } catch {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
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

    func getTitleAndContent() async throws -> GutenbergKit.EditorViewController.EditorTitleAndContent {
        navigationController?.view.isUserInteractionEnabled = false
        defer {
            navigationController?.view.isUserInteractionEnabled = true
        }

        return try await editorViewController.getTitleAndContent()
    }
}

// TODO: Copied
private extension CustomPostEditorViewController {
    func showEditorHelp() {
        guard let url = URL(string: "https://wordpress.com/support/wordpress-editor/") else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    func showFeedbackView() {
        self.present(SubmitFeedbackViewController(source: "gutenberg_kit", feedbackPrefix: "Editor"), animated: true)
    }

    func toggleEditingMode() {
        editorViewController.isCodeEditorEnabled.toggle()
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

    // TODO: Copied
    static let codeEditor = NSLocalizedString("postEditor.moreMenu.codeEditor", value: "Code Editor", comment: "Post Editor / Button in the 'More' menu")
    static let visualEditor = NSLocalizedString("postEditor.moreMenu.visualEditor", value: "Visual Editor", comment: "Post Editor / Button in the 'More' menu")
    static let preview = NSLocalizedString("postEditor.moreMenu.preview", value: "Preview", comment: "Post Editor / Button in the 'More' menu")
    static let revisions = NSLocalizedString("postEditor.moreMenu.revisions", value: "Revisions", comment: "Post Editor / Button in the 'More' menu")
    static let pageSettings = NSLocalizedString("postEditor.moreMenu.pageSettings", value: "Page Settings", comment: "Post Editor / Button in the 'More' menu")
    static let postSettings = NSLocalizedString("postEditor.moreMenu.postSettings", value: "Post Settings", comment: "Post Editor / Button in the 'More' menu")
    static let helpAndSupport = NSLocalizedString("postEditor.moreMenu.helpAndSupport", value: "Help & Support", comment: "Post Editor / Button in the 'More' menu")
    static let help = NSLocalizedString("postEditor.moreMenu.help", value: "Help", comment: "Post Editor / Button in the 'More' menu")
    static let sendFeedback = NSLocalizedString("postEditor.moreMenu.sendFeedback", value: "Send Feedback", comment: "Post Editor / Button in the 'More' menu")
    static let saveDraft = NSLocalizedString("postEditor.moreMenu.saveDraft", value: "Save Draft", comment: "Post Editor / Button in the 'More' menu")
    static let contentStructure = NSLocalizedString("postEditor.moreMenu.contentStructure", value: "Blocks: %li, Words: %li, Characters: %li", comment: "Post Editor / 'More' menu details labels with 'Blocks', 'Words' and 'Characters' counts as parameters (in that order)")
}
