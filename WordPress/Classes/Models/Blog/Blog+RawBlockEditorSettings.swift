import Foundation
import CoreData

extension Blog {
    private static let rawBlockEditorSettingsKey = "rawBlockEditorSettings"
    private static let rawBlockEditorSettingsLastFetchTimeKey = "rawBlockEditorSettingsLastFetchTime"

    /// Stores the raw block editor settings dictionary
    var rawBlockEditorSettings: [String: Any]? {
        get {
            return getOptionValue(Self.rawBlockEditorSettingsKey) as? [String: Any]
        }
        set {
            setValue(newValue, forOption: Self.rawBlockEditorSettingsKey)
        }
    }

    /// Stores the last time the raw block editor settings were fetched
    var rawBlockEditorSettingsLastFetchTime: Date? {
        get {
            return getOptionValue(Self.rawBlockEditorSettingsLastFetchTimeKey) as? Date
        }
        set {
            setValue(newValue, forOption: Self.rawBlockEditorSettingsLastFetchTimeKey)
        }
    }
}
