import Foundation

class EditorSettings: NSObject {
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
    // and then let the called configure the editor.
    func instantiatePostEditor(post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        switch (visualEditorEnabled, nativeEditorEnabled) {
        case (true, true):
            let vc = AztecPostViewController(post: post)
            configure(vc, vc)
            return vc
        case (true, false):
            let vc = WPPostViewController(post: post)
            configure(vc, vc)
            return vc
        case (false, _):
            let vc = WPLegacyEditPostViewController(post: post)
            configure(vc, vc)
            return vc
        default:
            fatalError()
        }
    }

    func instantiatePageEditor(page post: AbstractPost, configure: (PostEditor, UIViewController) -> Void) -> UIViewController {
        switch (visualEditorEnabled, nativeEditorEnabled) {
        case (true, true):
            let vc = AztecPostViewController(post: post)
            configure(vc, vc)
            return vc
        case (true, false):
            let vc = EditPageViewController(post: post)
            configure(vc, vc)
            return vc
        case (false, _):
            let vc = WPLegacyEditPageViewController(post: post)
            configure(vc, vc)
            return vc
        default:
            fatalError()
        }
    }
}
