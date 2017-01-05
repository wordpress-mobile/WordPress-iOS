import Foundation

class EditorSettings: NSObject {
    // MARK: - Constants
    fileprivate let newEditorAvailableKey = "kUserDefaultsNewEditorAvailable"
    fileprivate let newEditorEnabledKey = "kUserDefaultsNewEditorEnabled"
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

    var nativeEditorEnabled: Bool {
        get {
            if !FeatureFlag.nativeEditor.enabled {
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
}
