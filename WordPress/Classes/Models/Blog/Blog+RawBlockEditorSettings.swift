import Foundation
import CoreData

extension Blog {
    private static let rawBlockEditorSettingsKey = "rawBlockEditorSettings"

    /// Stores the raw block editor settings dictionary
    var rawBlockEditorSettings: [String: Any]? {
        get {
            return getOptionValue(Self.rawBlockEditorSettingsKey) as? [String: Any]
        }
        set {
            setValue(newValue, forOption: Self.rawBlockEditorSettingsKey)
        }
    }
}
