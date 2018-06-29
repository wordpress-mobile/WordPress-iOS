import Foundation
import Aztec
import WordPressEditor


// MARK: - VideoAttachment
//
extension VideoAttachment {

    @objc var videoPressID: String? {
        get {
            return extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute]
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute] = nonNilValue
            } else {
                extraAttributes.removeValue(forKey: VideoShortcodeProcessor.videoPressHTMLAttribute)
            }
        }
    }
}
