import Foundation

class EditorFactory {

    private let gutenbergSettings = GutenbergSettings()

    // MARK: - Editor: Editor Choice Logic

    /// Call this method to know if Gutenberg must be used for the specified post.
    ///
    /// - Parameters:
    ///     - post: the post that will be edited.
    ///
    /// - Returns: true if the post must be edited with Gutenberg.
    ///
    private func mustUseGutenberg(for post: AbstractPost) -> Bool {
        return gutenbergSettings.isGutenbergEnabled()
            && (!post.hasRemote() || post.containsGutenbergBlocks())
    }

    // MARK: - Editor: Instantiation

    /// We can't return a type that's both a PostEditor and a UIViewController, so using
    /// a configure block as a hack.
    /// In Swift 4, we'll be able to do `instantiateEditor() -> UIViewController & PostEditor`,
    /// and then let the caller configure the editor.
    func instantiatePostEditor(post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        if mustUseGutenberg(for: post) {
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
        if mustUseGutenberg(for: post) {
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
