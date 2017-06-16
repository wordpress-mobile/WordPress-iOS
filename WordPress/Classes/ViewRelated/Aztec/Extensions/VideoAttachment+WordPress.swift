import Foundation
import Aztec


// MARK: - VideoAttachment
//
extension VideoAttachment {

    var videoPressID: String? {
        get {
            return namedAttributes[VideoProcessor.videoPressHTMLAttribute]
        }
        set {
            if let nonNilValue = newValue {
                namedAttributes[VideoProcessor.videoPressHTMLAttribute] = nonNilValue
            } else {
                namedAttributes.removeValue(forKey: VideoProcessor.videoPressHTMLAttribute)
            }
        }
    }
}
