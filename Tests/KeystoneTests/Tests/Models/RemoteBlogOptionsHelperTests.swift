import Foundation
import Testing
import WordPressKitModels

struct RemoteBlogOptionsHelperTests {
    @Test(arguments: ["open", "closed"], ["open", "closed"])
    func mapsDiscussionDefaults(comments: String, pings: String) {
        let options: NSDictionary = [
            "default_comment_status": ["value": comments],
            "default_ping_status": ["value": pings]
        ]

        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)

        #expect(settings.commentsAllowed?.boolValue == (comments == "open"))
        #expect(settings.pingbackInboundEnabled?.boolValue == (pings == "open"))
    }

    @Test func missingDiscussionDefaultsStayUnknown() {
        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: [:])

        #expect(settings.commentsAllowed == nil)
        #expect(settings.pingbackInboundEnabled == nil)
    }

    @Test func invalidDiscussionDefaultDoesNotBecomeClosed() {
        let options: NSDictionary = [
            "default_comment_status": ["value": "invalid"],
            "default_ping_status": ["value": "open"]
        ]

        let settings = RemoteBlogOptionsHelper.remoteBlogSettings(fromXMLRPCDictionaryOptions: options)

        #expect(settings.commentsAllowed == nil)
        #expect(settings.pingbackInboundEnabled?.boolValue == true)
    }
}
