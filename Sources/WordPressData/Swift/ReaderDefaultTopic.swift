import Foundation

@objc(ReaderDefaultTopic)
open class ReaderDefaultTopic: ReaderAbstractTopic {
    override open class var TopicType: String {
        return "default"
    }
}
