import Foundation

/// This class takes care of instantiating the correct editor based on the App settings, feature flags,
/// etc.
///
class EditorFactory {

    /// Settings for the Gutenberg logic.
    ///
    private let gutenbergSettings = GutenbergSettings()
    typealias ReplaceEditorBlock = (EditorViewController, EditorViewController) -> ()

    // MARK: - Editor: Instantiation

    func instantiateEditor(for post: AbstractPost, loadAutosaveRevision: Bool = false, replaceEditor: @escaping ReplaceEditorBlock) -> EditorViewController {
        if gutenbergSettings.mustUseGutenberg(for: post) {
            return createGutenbergVC(with: post, loadAutosaveRevision: loadAutosaveRevision, replaceEditor: replaceEditor)
        } else {
            return AztecPostViewController(post: post, loadAutosaveRevision: loadAutosaveRevision, replaceEditor: replaceEditor)
        }
    }

    private func createGutenbergVC(with post: AbstractPost, loadAutosaveRevision: Bool, replaceEditor: @escaping ReplaceEditorBlock) -> GutenbergViewController {
        let gutenbergVC = GutenbergViewController(post: post, loadAutosaveRevision: loadAutosaveRevision, replaceEditor: replaceEditor)

        if gutenbergSettings.shouldAutoenableGutenberg(for: post) {
            gutenbergSettings.setGutenbergEnabled(true, for: post.blog, source: .onBlockPostOpening)
            gutenbergSettings.postSettingsToRemote(for: post.blog)
            gutenbergVC.shouldPresentInformativeDialog = true
            gutenbergSettings.willShowDialog(for: post.blog)
        }

        return gutenbergVC
    }

    func switchToAztec(from source: EditorViewController) {
        let replacement = AztecPostViewController(post: source.post, replaceEditor: source.replaceEditor, editorSession: source.editorSession)
        source.replaceEditor(source, replacement)
    }

    func switchToGutenberg(from source: EditorViewController) {
        let replacement = GutenbergViewController(post: source.post, replaceEditor: source.replaceEditor, editorSession: source.editorSession)
        source.replaceEditor(source, replacement)

    }
}
