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
            .addingPublicizeConnections(["1", "2", "3"], disabled: ["2"])

        #expect(Set(fields.keys()) == Set(["jetpack_publicize_connections"]))

        let entries = try #require(fields.arrayValueForKey(key: "jetpack_publicize_connections"))
        #expect(entries.count == 3)
        let flagsByID = Dictionary(
            uniqueKeysWithValues: entries.compactMap { entry -> (String, Bool)? in
                guard case let .object(dict) = entry,
                    case let .string(id)? = dict["connection_id"],
                    case let .bool(enabled)? = dict["enabled"]
                else {
                    return nil
                }
                return (id, enabled)
            }
        )
        #expect(flagsByID == ["1": true, "2": false, "3": true])
    }

    @Test("addingPublicizeMessage emits jetpack_publicize_message when message is set")
    func makeMetaEmitsMessage() throws {
        let meta = PostMeta().addingPublicizeMessage("Howdy")
        let value = try #require(meta.valueForKey(key: "jetpack_publicize_message"))
        guard case .string(let text) = value else {
            Issue.record("Expected jetpack_publicize_message to be a string, got \(value)")
            return
        }
        #expect(text == "Howdy")
    }

    @Test("init reads message from meta and connections from additional_fields")
    func initReadsBothSources() throws {
        let additionalFields = WpAdditionalFields()
            .addingPublicizeConnections(["5", "6"], disabled: ["5"])
        let meta = PostMeta().addingPublicizeMessage("Howdy")

        let parsed = PostSocialSharingDraft(fromPostAdditionalFields: additionalFields, meta: meta)

        #expect(parsed.customMessage == "Howdy")
        #expect(parsed.disabledConnectionIDs == ["5"])
    }

    @Test("init tolerates missing fields and missing meta")
    func initToleratesMissing() throws {
        let empty = try WpAdditionalFields.fromJsonString(json: "{}")
        let draft = PostSocialSharingDraft(fromPostAdditionalFields: empty, meta: PostMeta())
        #expect(draft.customMessage == nil)
        #expect(draft.disabledConnectionIDs.isEmpty)
    }

    @Test("init handles nil inputs")
    func initHandlesNil() {
        let draft = PostSocialSharingDraft(fromPostAdditionalFields: nil, meta: nil)
        #expect(draft.customMessage == nil)
        #expect(draft.disabledConnectionIDs.isEmpty)
    }

    @Test("init treats empty-string message as nil")
    func initTreatsEmptyMessageAsNil() {
        let meta = PostMeta().withValue(key: "jetpack_publicize_message", value: .string(""))
        let draft = PostSocialSharingDraft(fromPostAdditionalFields: nil, meta: meta)
        #expect(draft.customMessage == nil)
    }
}
