import Foundation
import Aztec


// MARK: - VideoAttachment
//
extension VideoAttachment {

    var videoPressID: String? {
        get {
            return extraAttributes[VideoProcessor.videoPressHTMLAttribute]
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes[VideoProcessor.videoPressHTMLAttribute] = nonNilValue
            } else {
                extraAttributes.removeValue(forKey: VideoProcessor.videoPressHTMLAttribute)
            }
        }
    }
}
