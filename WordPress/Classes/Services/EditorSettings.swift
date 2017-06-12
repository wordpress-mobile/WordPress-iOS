import Foundation

class EditorSettings: NSObject {
    enum Editor {
        case aztec
        case hybrid
        case legacy
    }

    // MARK: - Constants
    fileprivate let newEditorAvailableKey = "kUserDefaultsNewEditorAvailable"
    fileprivate let newEditorEnabledKey = "kUserDefaultsNewEditorEnabled"
    fileprivate let nativeEditorAvailableKey = "kUserDefaultsNativeEditorAvailable"
    fileprivate let nativeEditorEnabledKey = "kUserDefaultsNativeEditorEnabled"

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

    var editor: Editor {
        if visualEditorEnabled {
            if nativeEditorEnabled {
                return .aztec
            } else {
                return .hybrid
            }
        } else {
            return .legacy
        }
    }

    var visualEditorEnabled: Bool {
        get {
            if let visualEditorEnabled = database.object(forKey: newEditorEnabledKey) as? Bool {
                return visualEditorEnabled
            } else {
                return true
            }
        }
        set {
            database.set(newValue, forKey: newEditorEnabledKey)
        }
    }

    var nativeEditorAvailable: Bool {
        get {
            // If the available flag exists in user settings, return it's value
            if let nativeEditorAvailable = database.object(forKey: nativeEditorAvailableKey) as? Bool {
                return nativeEditorAvailable
            }

            // If the flag doesn't exist in settings, look at FeatureFlag
            return FeatureFlag.nativeEditor.enabled
        }
        set {
            database.set(newValue, forKey: nativeEditorAvailableKey)
        }
    }

    var nativeEditorEnabled: Bool {
        get {
            guard nativeEditorAvailable else {
                return false
            }

            if let nativeEditorEnabled = database.object(forKey: nativeEditorEnabledKey) as? Bool {
                return nativeEditorEnabled
            } else {
                return false
            }
        }
        set {
            database.set(newValue, forKey: nativeEditorEnabledKey)
        }
    }

    // We can't return a type that's both a PostEditor and a UIViewController, so using
    // a configure block as a hack.
    // In Swift 4, we'll be able to do `instantiateEditor() -> UIViewController & PostEditor`,
    // and then let the caller configure the editor.
    func instantiatePostEditor(post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        switch editor {
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
        switch editor {
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
