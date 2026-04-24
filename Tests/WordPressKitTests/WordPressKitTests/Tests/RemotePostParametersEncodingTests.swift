import Testing
@testable import WordPressKit

@Suite("RemotePostParameters Encoding Tests")
struct RemotePostParametersEncodingTests {

    /// Encodes a value using PropertyListEncoder and deserializes it to a
    /// dictionary, matching the production encoding pipeline.
    private func encodeToDictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(value)
        let object = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(object as? [String: Any])
    }

    // MARK: - XML-RPC Create Encoder

    @Test("XML-RPC create encoder always includes comment_status and ping_status")
    func xmlrpcCreateEncoderIncludesDiscussionByDefault() throws {
        let parameters = RemotePostCreateParameters(type: "post", status: "draft")
        #expect(parameters.discussion == .default, "Precondition: discussion should be at default")

        let encoder = RemotePostCreateParametersXMLRPCEncoder(parameters: parameters)
        let dictionary = try encodeToDictionary(encoder)

        #expect(dictionary["comment_status"] as? String == "open")
        #expect(dictionary["ping_status"] as? String == "open")
    }

    @Test("XML-RPC create encoder sends closed when comments are disabled")
    func xmlrpcCreateEncoderCommentsClosed() throws {
        var parameters = RemotePostCreateParameters(type: "post", status: "draft")
        parameters.discussion = RemotePostDiscussionSettings(allowComments: false, allowPings: false)

        let encoder = RemotePostCreateParametersXMLRPCEncoder(parameters: parameters)
        let dictionary = try encodeToDictionary(encoder)

        #expect(dictionary["comment_status"] as? String == "closed")
        #expect(dictionary["ping_status"] as? String == "closed")
    }

    // MARK: - WP.com REST Create Encoder

    @Test("WP.com REST create encoder always includes discussion settings")
    func wpcomCreateEncoderIncludesDiscussionByDefault() throws {
        let parameters = RemotePostCreateParameters(type: "post", status: "draft")
        #expect(parameters.discussion == .default, "Precondition: discussion should be at default")

        let encoder = RemotePostCreateParametersWordPressComEncoder(parameters: parameters)
        let dictionary = try encodeToDictionary(encoder)

        let discussion = try #require(dictionary["discussion"] as? [String: Any])
        #expect(discussion["comments_open"] as? Bool == true)
        #expect(discussion["pings_open"] as? Bool == true)
    }

    @Test("WP.com REST create encoder sends false when comments are disabled")
    func wpcomCreateEncoderCommentsClosed() throws {
        var parameters = RemotePostCreateParameters(type: "post", status: "draft")
        parameters.discussion = RemotePostDiscussionSettings(allowComments: false, allowPings: false)

        let encoder = RemotePostCreateParametersWordPressComEncoder(parameters: parameters)
        let dictionary = try encodeToDictionary(encoder)

        let discussion = try #require(dictionary["discussion"] as? [String: Any])
        #expect(discussion["comments_open"] as? Bool == false)
        #expect(discussion["pings_open"] as? Bool == false)
    }

    // MARK: - XML-RPC Update Encoder

    @Test("XML-RPC update encoder omits discussion when nil (no change)")
    func xmlrpcUpdateEncoderOmitsDiscussionWhenNil() throws {
        let parameters = RemotePostUpdateParameters()

        let encoder = RemotePostUpdateParametersXMLRPCEncoder(parameters: parameters)
        let dictionary = try encodeToDictionary(encoder)

        #expect(dictionary["comment_status"] == nil)
        #expect(dictionary["ping_status"] == nil)
    }

    @Test("XML-RPC update encoder includes discussion when set")
    func xmlrpcUpdateEncoderIncludesDiscussionWhenSet() throws {
        var parameters = RemotePostUpdateParameters()
        parameters.discussion = RemotePostDiscussionSettings(allowComments: false, allowPings: true)

        let encoder = RemotePostUpdateParametersXMLRPCEncoder(parameters: parameters)
        let dictionary = try encodeToDictionary(encoder)

        #expect(dictionary["comment_status"] as? String == "closed")
        #expect(dictionary["ping_status"] as? String == "open")
    }

    // MARK: - Diff (changes)

    @Test("Diff omits discussion when unchanged")
    func diffOmitsDiscussionWhenUnchanged() {
        let original = RemotePostCreateParameters(type: "post", status: "draft")
        let latest = RemotePostCreateParameters(type: "post", status: "draft")

        let changes = latest.changes(from: original)

        #expect(changes.discussion == nil)
    }

    @Test("Diff includes updated discussion when changed")
    func diffIncludesUpdatedDiscussion() {
        let original = RemotePostCreateParameters(type: "post", status: "draft")
        var latest = RemotePostCreateParameters(type: "post", status: "draft")
        latest.discussion = RemotePostDiscussionSettings(allowComments: false, allowPings: false)

        let changes = latest.changes(from: original)

        #expect(changes.discussion == RemotePostDiscussionSettings(allowComments: false, allowPings: false))
    }
}
