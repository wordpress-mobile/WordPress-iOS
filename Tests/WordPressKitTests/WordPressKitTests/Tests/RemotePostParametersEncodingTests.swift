import Foundation
import Testing
@testable import WordPressKit

struct RemotePostParametersEncodingTests {
    @Test(
        arguments: [
            (nil, nil, nil),
            (.open, nil, nil),
            (nil, .open, nil),
            (.open, .open, nil),
            (.closed, nil, ["comments_open": false, "pings_open": true]),
            (nil, .closed, ["comments_open": true, "pings_open": false]),
            (.closed, .open, ["comments_open": false, "pings_open": true]),
            (.open, .closed, ["comments_open": true, "pings_open": false]),
            (.closed, .closed, ["comments_open": false, "pings_open": false])
        ] as [(RemotePostDiscussionState?, RemotePostDiscussionState?, [String: Bool]?)]
    )
    func createEncodesDiscussion(
        commentStatus: RemotePostDiscussionState?,
        pingStatus: RemotePostDiscussionState?,
        restDiscussion: [String: Bool]?
    ) throws {
        var parameters = RemotePostCreateParameters(type: "post", status: "publish")
        parameters.commentStatus = commentStatus
        parameters.pingStatus = pingStatus

        let xmlrpc = try encode(RemotePostCreateParametersXMLRPCEncoder(parameters: parameters))
        #expect(xmlrpc["comment_status"] as? String == commentStatus?.rawValue)
        #expect(xmlrpc["ping_status"] as? String == pingStatus?.rawValue)

        let rest = try encode(RemotePostCreateParametersWordPressComEncoder(parameters: parameters))
        #expect(rest["discussion"] as? [String: Bool] == restDiscussion)
    }

    @Test func xmlrpcUpdateOmitsUnchangedDiscussion() throws {
        var parameters = RemotePostUpdateParameters()
        parameters.title = "Updated title"

        let body = try encode(RemotePostUpdateParametersXMLRPCEncoder(parameters: parameters))

        #expect(body["post_title"] as? String == "Updated title")
        #expect(body["comment_status"] == nil)
        #expect(body["ping_status"] == nil)
    }

    @Test(arguments: [true, false], [true, false])
    func xmlrpcUpdateSendsExplicitDiscussion(allowComments: Bool, allowPings: Bool) throws {
        var parameters = RemotePostUpdateParameters()
        parameters.discussion = .init(allowComments: allowComments, allowPings: allowPings)

        let body = try encode(RemotePostUpdateParametersXMLRPCEncoder(parameters: parameters))

        #expect(body["comment_status"] as? String == (allowComments ? "open" : "closed"))
        #expect(body["ping_status"] as? String == (allowPings ? "open" : "closed"))
    }

    private func encode(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
