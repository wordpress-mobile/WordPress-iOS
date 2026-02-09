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
    var post: AnyPostWithEditContext
    let details: PostTypeDetailsWithEditContext
    let completion: () -> Void

    private lazy var primarySaveButton = UIBarButtonItem(primaryAction: savePostAction())
    private lazy var redoButton = UIBarButtonItem(systemItem: .redo, primaryAction: UIAction {
        [weak editorViewController] _ in editorViewController?.redo() }
    )
    private lazy var undoButton = UIBarButtonItem(systemItem: .undo, primaryAction: UIAction {
        [weak editorViewController] _ in editorViewController?.undo() }
    )

    init(
        blog: Blog,
        client: WordPressClient,
        post: AnyPostWithEditContext,
        details: PostTypeDetailsWithEditContext,
        completion: @escaping () -> Void
    ) {
        precondition(post.id > 0, "No new post support yet")

        self.client = client
        self.post = post
        self.details = details
        self.completion = completion

        let postTypeDetails = PostTypeDetails(
            postType: details.slug,
            restBase: details.restBase,
            restNamespace: details.restNamespace
        )
        super.init(
            postId: Int(post.id),
            postType: postTypeDetails,
            title: post.title?.raw,
            content: post.content.raw,
            status: post.status.description,
            blog: blog
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonAction))
        navigationItem.rightBarButtonItems = rightBarButtonItems()
        redoButton.isEnabled = false
        undoButton.isEnabled = false
    }

    override func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateHistoryState state: EditorState) {
        redoButton.isEnabled = state.hasRedo
        undoButton.isEnabled = state.hasUndo
    }

    private func hasUnsavedChanges() async throws -> Bool {
        let content = try await self.editorViewController.getTitleAndContent()
        // We can't use `content.changed` here, because it means whether the content has changed since last `getTitleAndContent` call.
        return content.title != post.title?.raw || content.content != post.content.raw
    }
}

// MARK: - Navigation bar buttons

private extension CustomPostEditorViewController {
    @objc func closeButtonAction() {
        Task {
            await dismiss()
        }
    }

    func dismiss() async {
        navigationController?.view.isUserInteractionEnabled = false
        defer {
            navigationController?.view.isUserInteractionEnabled = true
        }

        let changed: Bool
        do {
            changed = try await hasUnsavedChanges()
        } catch {
            DDLogError("Failed to get editor content: \(error)")
            return
        }

        if changed {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addCancelActionWithTitle(PostEditorStrings.keepEditing)
            alert.addDestructiveActionWithTitle(PostEditorStrings.discardChanges) { [weak self] _ in
                self?.navigationController?.dismiss(animated: true)
            }
            if post.status == .draft {
                alert.addAction(UIAlertAction(title: PostEditorStrings.saveDraft, style: .default, handler: { [weak self] _ in
                    Task {
                        await self?.save(publish: false)
                    }
                }))
            }

            alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            self.present(alert, animated: true)
        } else {
            self.navigationController?.dismiss(animated: true)
        }
    }

    func rightBarButtonItems() -> [UIBarButtonItem] {
        var children: [UIMenuElement] = [editorModeToggle(), helpAction(), feedbackAction()]
        if post.status == .draft {
            let menu = UIDeferredMenuElement.uncached { [weak self] resolve in
                Task {
                    let enabled = (try? await self?.hasUnsavedChanges()) == true
                    let saveDraft = UIAction(
                        title: PostEditorStrings.saveDraft,
                        image: UIImage(systemName: "doc"),
                        attributes: enabled ? [] : [.disabled]) { [weak self] _ in
                            Task {
                                await self?.save(publish: false)
                            }
                        }
                    resolve([saveDraft])
                }
            }
            children.append(UIMenu(options: .displayInline, children: [menu]))
        }
        let moreMenu = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: UIMenu(children: children))

        if #available(iOS 26, *) {
            return [primarySaveButton, separator(), moreMenu, redoButton, undoButton]
        } else {
            return [primarySaveButton, separator(), moreMenu, separator(), redoButton, separator(), undoButton]
        }
    }

    private func savePostAction() -> UIAction {
        precondition(post.id > 0, "No new post support yet")

        if post.status == .draft {
            return UIAction(title: PostEditorStrings.publish) { [weak self] _ in
                Task {
                    await self?.save(publish: true)
                }
            }
        } else {
            return UIAction(title: PostEditorStrings.update) { [weak self] _ in
                Task {
                    await self?.save(publish: false)
                }
            }
        }
    }

    private func separator() -> UIBarButtonItem {
        UIBarButtonItem(systemItem: .fixedSpace)
    }
}

// MARK: - Update post

private extension CustomPostEditorViewController {

    func save(publish: Bool) async {
        SVProgressHUD.show()

        do {
            let data = try await editorViewController.getTitleAndContent()

            try await update(title: data.title, content: data.content, publish: publish)
            dismissHUDWithSuccess()

            if publish {
                completion()
            }
        } catch {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }

    private func hasBeenModified() async throws -> Bool {
        let lastModified = try await client.api.posts
            .filterRetrieveWithEditContext(
                postEndpointType: details.toPostEndpointType(),
                postId: post.id,
                params: .init(),
                fields: [.modified]
            )
            .data
            .modified
        return lastModified != post.modified
    }

    private func update(title: String, content: String, publish: Bool) async throws {
        // This is a simple way to avoid overwriting others' changes. We can further improve it
        // to align with the implementation in `PostRepository`.
        guard try await !hasBeenModified() else { throw PostUpdateError.conflicts }

        let endpoint = details.toPostEndpointType()
        let hasTitle = details.supports.map[.title] == .bool(true)
        let params = PostUpdateParams(
            status: publish ? .publish : nil,
            title: hasTitle ? title : nil,
            content: content,
            meta: nil
        )
        let post = try await client.api
            .posts
            .update(
                postEndpointType: endpoint,
                postId: post.id,
                params: params
            )
            .data
        self.post = post

        // Refresh post in the background. This ensures the post list is up-to-date with the new changes.
        Task {
            try await client.service.posts().refreshPost(postId: post.id, endpointType: endpoint)
        }
    }

    private func dismissHUDWithSuccess() {
        SVProgressHUD.showSuccess(withStatus: nil)
        SVProgressHUD.dismiss(withDelay: 1)
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
