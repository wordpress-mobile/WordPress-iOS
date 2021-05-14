import Foundation
import CoreData

extension Blog {

    /// Stores the relationship to the `BlockEditorSettings` which is an optional entity that holds settings realated to the BlockEditor. These are features
    /// such as Global Styles and Full Site Editing settings and capabilities. 
    ///
    @NSManaged public var blockEditorSettings: BlockEditorSettings?

    @objc
    func supportsBlockEditorSettings() -> Bool {
        guard FeatureFlag.globalStyleSettings.enabled else { return false }
        guard let version = version else { return false }
        // This a Placeholder for when we want to enable this for specific .com versions
//        let isReleased = [.orderedSame, .orderedDescending].contains(version.compare("5.8", options: .numeric))
        return true
    }
}
