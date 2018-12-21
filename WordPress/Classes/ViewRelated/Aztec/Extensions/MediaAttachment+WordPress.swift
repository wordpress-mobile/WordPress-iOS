import Foundation
import Aztec


// MARK: - MediaAttachment
//
extension MediaAttachment {

    static let uploadKey = "data-wp_upload_id"

    var uploadID: String? {
        get {
            return extraAttributes[MediaAttachment.uploadKey]?.toString()
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes[MediaAttachment.uploadKey] = .string(String(nonNilValue))
            } else {
                extraAttributes.remove(named: MediaAttachment.uploadKey)
            }
        }
    }
}
