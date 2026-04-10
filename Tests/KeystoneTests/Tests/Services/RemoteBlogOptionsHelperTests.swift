import Testing
@testable import WordPressKit

struct RemoteBlogOptionsHelperTests {

    // MARK: - Helpers

    /// Build a minimal XML-RPC options dictionary in the `wp.getOptions` format:
    /// `{ "key": { "value": ... } }`
    private func makeOptions(_ entries: [String: String]) -> NSDictionary {
        let dict = NSMutableDictionary()
        for (key, value) in entries {
            dict[key] = ["value": value]
        }
        return dict
    }

    // MARK: - Discussion settings

    @Test func mapsDefaultCommentStatusOpen() {
        let options = makeOptions(["default_comment_status": "open"])
        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)
        #expect(settings.commentsAllowed == NSNumber(value: true))
    }

    @Test func mapsDefaultCommentStatusClosed() {
        let options = makeOptions(["default_comment_status": "closed"])
        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)
        #expect(settings.commentsAllowed == NSNumber(value: false))
    }

    @Test func mapsDefaultPingStatusOpen() {
        let options = makeOptions(["default_ping_status": "open"])
        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)
        #expect(settings.pingbackInboundEnabled == NSNumber(value: true))
    }

    @Test func mapsDefaultPingStatusClosed() {
        let options = makeOptions(["default_ping_status": "closed"])
        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)
        #expect(settings.pingbackInboundEnabled == NSNumber(value: false))
    }

    @Test func leavesCommentsAllowedNilWhenKeyMissing() {
        let options = makeOptions(["blog_title": "Test"])
        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)
        #expect(settings.commentsAllowed == nil)
    }

    @Test func leavesPingStatusNilWhenKeyMissing() {
        let options = makeOptions(["blog_title": "Test"])
        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)
        #expect(settings.pingbackInboundEnabled == nil)
    }
}
