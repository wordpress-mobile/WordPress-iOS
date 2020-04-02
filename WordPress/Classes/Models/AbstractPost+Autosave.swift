import Foundation

extension AbstractPost {
    /// An autosave revision may include post title, content and/or excerpt.
    var hasAutosaveRevision: Bool {
        guard let autosaveRevisionIdentifier = autosaveIdentifier?.intValue else {
            return false
        }
        return autosaveRevisionIdentifier > 0
    }
}
