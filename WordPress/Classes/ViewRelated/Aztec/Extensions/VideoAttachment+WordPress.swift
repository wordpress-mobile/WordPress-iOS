import Foundation
import Aztec
import WordPressEditor


// MARK: - VideoAttachment
//
extension VideoAttachment {

    @objc var videoPressID: String? {
        get {
            return extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute]?.toString()
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute] = .string(String(nonNilValue))
            } else {
                extraAttributes.remove(named: VideoShortcodeProcessor.videoPressHTMLAttribute)
            }
        }
    }
}
