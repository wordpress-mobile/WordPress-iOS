import Foundation

class EditorSettings: NSObject {
    @objc
    enum Editor: Int {
        case legacy
        case hybrid
        case aztec
    }

    // MARK: - Enabled Editors Keys
    
    fileprivate let hybridEditorEnabledKey = "kUserDefaultsNewEditorEnabled"
    fileprivate let aztecEditorEnabledKey = "kUserDefaultsNativeEditorEnabled"
    
    // MARK: - Forcing Aztec Keys

    fileprivate let lastVersionWhereAztecWasForced = "lastVersionWhereAztecWasForced"

    // MARK: - Internal variables
    fileprivate let database: KeyValueDatabase

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
        super.init()
        
        setDefaultsForVersionFirstLaunch()
    }

    convenience override init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }
    
    // MARK: - Native Editor By Default
    
    fileprivate let aztecEditorMadeDefault = "aztecEditorMadeDefault"
    
    /// Contains the logic for setting the defaults the first time a version is launched.
    ///
    func setDefaultsForVersionFirstLaunch() {
        let bundleVersion = Bundle.main.bundleVersion()
        
        let lastInternalForcedVersion = database.object(forKey: lastVersionWhereAztecWasForced) as? String ?? ""
        
        guard lastInternalForcedVersion != bundleVersion else {
            return
        }
        
        enable(.aztec)
        database.set(bundleVersion, forKey: lastVersionWhereAztecWasForced)
    }

    // MARK: Public accessors

    private var current: Editor {
        let hybridEditorEnabled = database.object(forKey: hybridEditorEnabledKey) as? Bool ?? false
        let nativeEditorEnabled = database.object(forKey: aztecEditorEnabledKey) as? Bool ?? false
        
        if nativeEditorEnabled {
            return .aztec
        } else if hybridEditorEnabled {
            return .hybrid
        } else {
            return .legacy
        }
    }
    
    func isEnabled(_ editor: Editor) -> Bool {
        return current == editor
    }
    
    /// Enables the specified editor.
    ///
    func enable(_ editor: Editor) {
        
        // Tracking ON and OFF for Aztec specifically.
        if editor == .aztec && !isEnabled(.aztec) {
            WPAnalytics.track(.editorToggledOn)
        } else if editor != .aztec && isEnabled(.aztec) {
            WPAnalytics.track(.editorToggledOff)
        }
        
        switch editor {
        case .legacy:
            database.set(false, forKey: hybridEditorEnabledKey)
            database.set(false, forKey: aztecEditorEnabledKey)
        case .hybrid:
            database.set(true, forKey: hybridEditorEnabledKey)
            database.set(false, forKey: aztecEditorEnabledKey)
        case .aztec:
            database.set(false, forKey: hybridEditorEnabledKey)
            database.set(true, forKey: aztecEditorEnabledKey)
        }
    }

    // We can't return a type that's both a PostEditor and a UIViewController, so using
    // a configure block as a hack.
    // In Swift 4, we'll be able to do `instantiateEditor() -> UIViewController & PostEditor`,
    // and then let the caller configure the editor.
    func instantiatePostEditor(post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        switch current {
        case .aztec:
            let vc = AztecPostViewController(post: post)
            configure(vc, vc)
            return vc
        case .hybrid:
            let vc = WPPostViewController(post: post, mode: .edit)
            configure(vc, vc)
            return vc
        case .legacy:
            let vc = WPLegacyEditPostViewController(post: post)
            configure(vc, vc)
            return vc
        }
    }

    func instantiatePageEditor(page post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        switch current {
        case .aztec:
            let vc = AztecPostViewController(post: post)
            configure(vc, vc)
            return vc
        case .hybrid:
            let vc = EditPageViewController(post: post)
            configure(vc, vc)
            return vc
        case .legacy:
            let vc = WPLegacyEditPageViewController(post: post)
            configure(vc, vc)
            return vc
        }
    }
}
