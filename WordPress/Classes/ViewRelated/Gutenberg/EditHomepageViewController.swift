import Foundation

class EditHomepageViewController: GutenbergViewController {
    required init(
        post: AbstractPost,
        loadAutosaveRevision: Bool = false,
        replaceEditor: @escaping ReplaceEditorCallback,
        editorSession: PostEditorAnalyticsSession? = nil,
        navigationBarManager: PostEditorNavigationBarManager? = nil
    ) {
        let navigationBarManager = navigationBarManager ?? HomepageEditorNavigationBarManager()
        super.init(post: post, loadAutosaveRevision: loadAutosaveRevision, replaceEditor: replaceEditor, editorSession: editorSession, navigationBarManager: navigationBarManager)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) lazy var homepageEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self, action: .continueFromHomepageEditing)
    }()

    override var postEditorStateContext: PostEditorStateContext {
        return homepageEditorStateContext
    }

    // If there are changes, offer to save them, otherwise continue will dismiss the editor with no changes.
    override func continueFromHomepageEditing() {
        if editorHasChanges {
            handlePublishButtonTap()
        } else {
            cancelEditing()
        }
    }
}

extension EditHomepageViewController: HomepageEditorNavigationBarManagerDelegate {
    var continueButtonText: String {
        return postEditorStateContext.publishButtonText
    }

    func navigationBarManager(_ manager: HomepageEditorNavigationBarManager, continueWasPressed sender: UIButton) {
        requestHTML(for: .continueFromHomepageEditing)
    }
}
