import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import JetpackSocial

@Suite("PostSocialSharingDraft")
struct PostSocialSharingDraftTests {
    @Test("addingPublicizeConnections emits every connection with explicit enabled flag")
    func emitsAllConnections() throws {
        let fields = WpAdditionalFields()
            .addingPublicizeConnections([
                "1": .init(id: "1", enabled: true),
                "2": .init(id: "2", enabled: false),
                "3": .init(id: "3", enabled: true)
            ])

        #expect(Set(fields.keys()) == Set(["jetpack_publicize_connections"]))
        #expect(
            fields.publicizeConnectionsByID == [
                "1": .init(id: "1", enabled: true),
                "2": .init(id: "2", enabled: false),
                "3": .init(id: "3", enabled: true)
            ]
        )
    }

    @Test("publicizeConnectionsByID distinguishes missing and empty fields")
    func parsesMissingAndEmptyConnectionsDifferently() throws {
        let missing = try WpAdditionalFields.fromJsonString(json: "{}")
        #expect(missing.publicizeConnectionsByID == nil)

        let empty = try WpAdditionalFields.fromJsonString(
            json: #"{"jetpack_publicize_connections":[]}"#
        )
        #expect(empty.publicizeConnectionsByID == [String: PostSocialSharingDraft.Connection]())
    }

    @Test("addingPublicizeMessage round-trips through publicizeMessage")
    func makeMetaEmitsMessage() {
        let meta = PostMeta().addingPublicizeMessage("Howdy")
        #expect(meta.publicizeMessage == "Howdy")
    }

    @Test("init reads message from meta and connections from additional_fields")
    func initReadsBothSources() throws {
        let additionalFields = WpAdditionalFields()
            .addingPublicizeConnections([
                "5": .init(id: "5", enabled: false),
                "6": .init(id: "6", enabled: true)
            ])
        let meta = PostMeta().addingPublicizeMessage("Howdy")

        let parsed = PostSocialSharingDraft(fromPostAdditionalFields: additionalFields, meta: meta)

        #expect(parsed.customMessage == "Howdy")
        #expect(
            parsed.connectionsByID == [
                "5": .init(id: "5", enabled: false),
                "6": .init(id: "6", enabled: true)
            ]
        )
    }

    @Test("init tolerates missing fields and missing meta")
    func initToleratesMissing() throws {
        let empty = try WpAdditionalFields.fromJsonString(json: "{}")
        let draft = PostSocialSharingDraft(fromPostAdditionalFields: empty, meta: PostMeta())
        #expect(draft.customMessage == nil)
        #expect(draft.connectionsByID == nil)
    }

    @Test("init handles nil inputs")
    func initHandlesNil() {
        let draft = PostSocialSharingDraft(fromPostAdditionalFields: nil, meta: nil)
        #expect(draft.customMessage == nil)
        #expect(draft.connectionsByID == nil)
    }

    @Test("init treats empty-string message as nil")
    func initTreatsEmptyMessageAsNil() {
        let meta = PostMeta().addingPublicizeMessage("")
        let draft = PostSocialSharingDraft(fromPostAdditionalFields: nil, meta: meta)
        #expect(draft.customMessage == nil)
    }

    @Test("connections equality is independent of dictionary literal order")
    func connectionsEqualityIsOrderIndependent() {
        let lhs = PostSocialSharingDraft(connectionsByID: [
            "1": .init(id: "1", enabled: true),
            "2": .init(id: "2", enabled: false)
        ])
        let rhs = PostSocialSharingDraft(connectionsByID: [
            "2": .init(id: "2", enabled: false),
            "1": .init(id: "1", enabled: true)
        ])

        #expect(lhs == rhs)
    }
}
