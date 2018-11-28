import Foundation

/// This class takes care of instantiating the correct editor based on the App settings, feature flags,
/// etc.
///
class EditorFactory {

    /// Settings for the Gutenberg logic.
    ///
    private let gutenbergSettings = GutenbergSettings()

    // MARK: - Editor: Instantiation

    func instantiateEditor(for post: AbstractPost) -> UIViewController & PostEditor {
        if gutenbergSettings.mustUseGutenberg(for: post) {
            return GutenbergViewController(post: post)
        } else {
            return AztecPostViewController(post: post)
        }
    }
}
