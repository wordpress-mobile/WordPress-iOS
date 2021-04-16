import Foundation
import CoreData

extension Blog {

    /// Stores the relationship to the `BlockEditorSettings` which is an optional entity that holds settings realated to the BlockEditor. These are features
    /// such as Global Styles and Full Site Editing settings and capabilities. 
    ///
    @NSManaged public var blockEditorSettings: BlockEditorSettings?
}
