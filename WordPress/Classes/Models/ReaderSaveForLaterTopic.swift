/// This is basically a mock at the moment. It models a mock topic, so that I can test that the topic gets renderd in the UI
final class ReaderSaveForLaterTopic: ReaderAbstractTopic {
    init(title: String) {
        super.init(entity: NSEntityDescription(), insertInto: nil)
        self.title = title
        self.path = "/read/saved"
    }

    override open class var TopicType: String {
        return "saveForLater"
    }
}
