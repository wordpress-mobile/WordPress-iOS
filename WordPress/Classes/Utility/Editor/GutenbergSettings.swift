import Foundation

class GutenbergSettings: NSObject {

    // MARK: - Enabled Editors Keys

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

    @objc func isGutenbergEnabled() -> Bool {
        return database.object(forKey: gutenbergEditorEnabledKey) as? Bool ?? false
    }

    @objc func toggleGutenberg() {
        if isGutenbergEnabled() {
            database.set(false, forKey: gutenbergEditorEnabledKey)
        } else {
            database.set(true, forKey: gutenbergEditorEnabledKey)
        }
    }
}
