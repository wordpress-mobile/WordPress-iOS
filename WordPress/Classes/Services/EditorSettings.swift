import Foundation

class EditorSettings: NSObject {
    @objc
    enum Editor: Int {
        case aztec
        case gutenberg
    }

    // MARK: - Enabled Editors Keys

    fileprivate let aztecEditorEnabledKey = "kUserDefaultsNativeEditorEnabled"
    fileprivate let gutenbergEditorEnabledKey = "kUserDefaultsGutenbergEditorEnabled"

    // MARK: - Internal variables
    fileprivate let database: KeyValueDatabase

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
        super.init()
    }

    convenience override init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }

    // MARK: Public accessors

    private var current: Editor {
        return Feature.enabled(.gutenberg) ? .gutenberg : .aztec
    }

    @objc func isEnabled(_ editor: Editor) -> Bool {
        return current == editor
    }

    /// Enables the specified editor.
    ///
    @objc func enable(_ editor: Editor) {

        // Tracking ON and OFF for Aztec specifically.
        if editor == .aztec && !isEnabled(.aztec) {
            WPAnalytics.track(.editorToggledOn)
        } else if editor != .aztec && isEnabled(.aztec) {
            WPAnalytics.track(.editorToggledOff)
        }

        switch editor {
        case .aztec:
            database.set(true, forKey: aztecEditorEnabledKey)
        case .gutenberg:
            database.set(false, forKey: aztecEditorEnabledKey)
        }
    }

    // MARK: - Editor: Choice Logic

    /// Call this method to know if Gutenberg must be used for the specified post.
    ///
    /// - Parameters:
    ///     - post: the post that will be edited.
    ///
    /// - Returns: true if the post must be edited with Gutenberg.
    ///
    private func useGutenberg(for post: AbstractPost) -> Bool {
        return Feature.enabled(.gutenberg) && post.containsGutenbergBlocks()
    }

    // MARK: - Editor: Instantiation

    /// We can't return a type that's both a PostEditor and a UIViewController, so using
    /// a configure block as a hack.
    /// In Swift 4, we'll be able to do `instantiateEditor() -> UIViewController & PostEditor`,
    /// and then let the caller configure the editor.
    func instantiatePostEditor(post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        if useGutenberg(for: post) {
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
        if useGutenberg(for: post) {
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
