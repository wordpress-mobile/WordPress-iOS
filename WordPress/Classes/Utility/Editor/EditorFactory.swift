import Foundation
import WordPressData

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
            if RemoteFeatureFlag.newGutenberg.enabled() {
                return NewGutenbergViewController(post: post, replaceEditor: replaceEditor)
            }
            return createGutenbergVC(with: post, replaceEditor: replaceEditor)
        } else {
            return AztecPostViewController(post: post, replaceEditor: replaceEditor)
        }
    }

    func createGutenbergVC(with post: AbstractPost, replaceEditor: @escaping ReplaceEditorBlock) -> GutenbergViewController {
        let gutenbergVC = GutenbergViewController(post: post, replaceEditor: replaceEditor)

        if gutenbergSettings.shouldAutoenableGutenberg(for: post) {
            gutenbergSettings.setGutenbergEnabled(true, for: post.blog, source: .onBlockPostOpening)
            gutenbergSettings.postSettingsToRemote(for: post.blog)
            gutenbergVC.shouldPresentInformativeDialog = true
            gutenbergSettings.willShowDialog(for: post.blog)
        }

        return gutenbergVC
    }

    func switchToGutenberg(from source: EditorViewController) {
        let replacement = GutenbergViewController(post: source.post, replaceEditor: source.replaceEditor, editorSession: source.editorSession)
        source.replaceEditor(source, replacement)
    }

    // MARK: - Application Password Check

    /// Determines if an application password is required for editing this post
    /// Only returns true when NewGutenbergViewController would be used and application password is needed
    /// - Parameter post: The post to be edited
    /// - Returns: true if application password prompt should be shown
    func requiresApplicationPasswordForEditor(post: AbstractPost) -> Bool {
        guard gutenbergSettings.mustUseGutenberg(for: post) &&
              RemoteFeatureFlag.newGutenberg.enabled() else {
            return false
        }

        // Only require application password for non-WPCOM Simple sites (self-hosted sites)
        let blog = post.blog
        guard !blog.isHostedAtWPcom && !blog.isAtomic() else {
            return false
        }

        let hasApplicationPassword = (try? blog.getApplicationToken()) != nil
        return !hasApplicationPassword
    }
}
