import Foundation

/// This class takes care of instantiating the correct editor based on the App settings, feature flags,
/// etc.
///
class EditorFactory {

    /// Settings for the Gutenberg logic.
    ///
    private let gutenbergSettings = GutenbergSettings()

    // MARK: - Editor: Instantiation

    func instantiateEditor(
        for post: AbstractPost,
        replaceEditor: @escaping (EditorViewController, EditorViewController) -> ()) -> EditorViewController {

        if gutenbergSettings.mustUseGutenberg(for: post) {
            if gutenbergSettings.shouldAutoenableGutenberg(for: post) {
                gutenbergSettings.setGutenbergEnabledIfNeeded()
            }
            gutenbergSettings.setToRemote()
            return GutenbergViewController(post: post, replaceEditor: replaceEditor)
        } else {
            gutenbergSettings.setToRemote()
            return AztecPostViewController(post: post, replaceEditor: replaceEditor)
        }
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
