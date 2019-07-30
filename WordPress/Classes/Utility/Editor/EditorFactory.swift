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

    func instantiateEditor(for post: AbstractPost, replaceEditor: @escaping ReplaceEditorBlock) -> EditorViewController {
        if gutenbergSettings.mustUseGutenberg(for: post) {
            return createGutenbergVC(with: post, replaceEditor: replaceEditor)
        } else {
            return AztecPostViewController(post: post, replaceEditor: replaceEditor)
        }
    }

    private func createGutenbergVC(with post: AbstractPost, replaceEditor: @escaping ReplaceEditorBlock) -> GutenbergViewController {
        let gutenbergVC = GutenbergViewController(post: post, replaceEditor: replaceEditor)

        if gutenbergSettings.shouldAutoenableGutenberg(for: post) {
            gutenbergSettings.setGutenbergEnabled(true, for: post.blog)
            gutenbergSettings.postSettingsToRemote(for: post.blog)
            gutenbergVC.shouldPresentInformativeDialog = true
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
