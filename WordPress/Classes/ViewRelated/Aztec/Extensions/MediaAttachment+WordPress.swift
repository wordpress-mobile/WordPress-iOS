import Foundation
import Aztec


// MARK: - MediaAttachment
//
extension MediaAttachment {

    static let uploadKey = "data-wp_upload_id"

    var uploadID: String? {
        get {
            return extraAttributes[MediaAttachment.uploadKey]
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes[MediaAttachment.uploadKey] = "\(nonNilValue)"
            } else {
                extraAttributes.removeValue(forKey: MediaAttachment.uploadKey)
            }
        }
    }
}
