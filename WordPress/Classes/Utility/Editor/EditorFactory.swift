import Foundation

/// This class takes care of instantiating the correct editor based on the App settings, feature flags,
/// etc.
///
class EditorFactory {

    /// Settings for the Gutenberg logic.
    ///
    private let gutenbergSettings = GutenbergSettings()

    // MARK: - Editor: Instantiation

    /// We can't return a type that's both a PostEditor and a UIViewController, so using
    /// a configure block as a hack.
    /// In Swift 4, we'll be able to do `instantiateEditor() -> UIViewController & PostEditor`,
    /// and then let the caller configure the editor.
    func instantiatePostEditor(post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        if gutenbergSettings.mustUseGutenberg(for: post) {
            let vc = GutenbergViewController(post: post)
            configure(vc, vc)
            return vc
        } else {
            let vc = AztecPostViewController(post: post)
            configure(vc, vc)
            return vc
        }
    }

    func instantiatePageEditor(page post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        if gutenbergSettings.mustUseGutenberg(for: post) {
            let vc = GutenbergViewController(post: post)
            configure(vc, vc)
            return vc
        } else {
            let vc = AztecPostViewController(post: post)
            configure(vc, vc)
            return vc
        }
    }
}
