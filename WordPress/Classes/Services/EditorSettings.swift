import Foundation

class EditorSettings: NSObject {
    // MARK: - Constants
    private let newEditorAvailableKey = "kUserDefaultsNewEditorAvailable"
    private let newEditorEnabledKey = "kUserDefaultsNewEditorEnabled"
    private let nativeEditorEnabledKey = "kUserDefaultsNativeEditorEnabled"

    // MARK: - Internal variables
    private let database: KeyValueDatabase

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
        super.init()
    }

    convenience override init() {
        self.init(database: NSUserDefaults())
    }

    // MARK: Public accessors


    var visualEditorEnabled: Bool {
        get {
            if let visualEditorEnabled = database.objectForKey(newEditorEnabledKey) as? Bool {
                return visualEditorEnabled
            } else {
                return true
            }
        }
        set {
            database.setObject(newValue, forKey: newEditorEnabledKey)
        }
    }

    var nativeEditorEnabled: Bool {
        get {
            if !FeatureFlag.NativeEditor.enabled {
                return false
            }
            if let nativeEditorEnabled = database.objectForKey(nativeEditorEnabledKey) as? Bool {
                return nativeEditorEnabled
            } else {
                return false
            }
        }
        set {
            database.setObject(newValue, forKey: nativeEditorEnabledKey)
        }
    }
}
