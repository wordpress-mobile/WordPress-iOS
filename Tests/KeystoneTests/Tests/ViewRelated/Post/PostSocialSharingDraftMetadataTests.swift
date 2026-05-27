import Foundation
import JetpackSocial
import Testing
@testable import WordPress
@testable import WordPressData

@Suite("PostSocialSharingDraft metadata bridge")
struct PostSocialSharingDraftMetadataTests {
    @Test("seed reads disabled connections and message")
    func seedReadsDisabledConnectionsAndMessage() {
        let container = PostMetadataContainer(metadata: [
            ["key": "_wpas_mess", "value": "Hello"],
            ["key": "_wpas_skip_publicize_111", "value": "1"],
            ["key": "_wpas_skip_publicize_222", "value": "0"],
            ["key": "_wpas_skip_333", "value": "1"],
            ["key": "unrelated", "value": "value"]
        ])

        let draft = PostSocialSharingDraft(socialMetadata: container)

        #expect(draft.customMessage == "Hello")
        #expect(!draft.isEnabled(connectionID: "111"))
        #expect(draft.isEnabled(connectionID: "222"))
        #expect(draft.isEnabled(connectionID: "999"))
    }

    @Test("seed treats empty message as nil")
    func seedTreatsEmptyMessageAsNil() {
        let container = PostMetadataContainer(metadata: [
            ["key": "_wpas_mess", "value": ""]
        ])

        let draft = PostSocialSharingDraft(socialMetadata: container)

        #expect(draft.customMessage == nil)
    }

    @Test("serialize writes connection scheme and message")
    func serializeWritesConnectionSchemeAndMessage() {
        var container = PostMetadataContainer(metadata: [
            ["id": "11", "key": "_wpas_skip_publicize_111", "value": "1"]
        ])
        let draft = PostSocialSharingDraft(
            customMessage: "Hi",
            connectionsByID: [
                "111": .init(id: "111", enabled: true),
                "222": .init(id: "222", enabled: false)
            ]
        )

        draft.applySocialMetadata(to: &container)

        #expect(container.entry(forKey: "_wpas_skip_publicize_111")?["id"] as? String == "11")
        #expect(container.getString(for: "_wpas_skip_publicize_111") == "0")
        #expect(container.getString(for: "_wpas_skip_publicize_222") == "1")
        #expect(container.getString(for: "_wpas_mess") == "Hi")
    }

    @Test("serialize clears message only when it previously existed")
    func serializeClearsMessageOnlyWhenItPreviouslyExisted() {
        var containerWithMessage = PostMetadataContainer(metadata: [
            ["key": "_wpas_mess", "value": "Previous"]
        ])
        let draft = PostSocialSharingDraft(customMessage: nil)

        draft.applySocialMetadata(to: &containerWithMessage)

        #expect(containerWithMessage.getString(for: "_wpas_mess")?.isEmpty == true)

        var containerWithoutMessage = PostMetadataContainer()

        draft.applySocialMetadata(to: &containerWithoutMessage)

        #expect(containerWithoutMessage.entry(forKey: "_wpas_mess") == nil)
    }

    @Test("upload entries include only publicize keys")
    func uploadEntriesIncludeOnlyPublicizeKeys() {
        let container = PostMetadataContainer(metadata: [
            ["key": "_wpas_mess", "value": "Hello"],
            ["key": "_wpas_skip_publicize_111", "value": "1"],
            ["key": "_wpas_skip_222", "value": "1"],
            ["key": "_jetpack_newsletter_access", "value": "subscribers"],
            ["key": "unrelated", "value": "value"]
        ])

        let entries = SocialSharingMetadata.publicizeEntries(in: container)
        let keys = Set(entries.compactMap { $0["key"] as? String })

        #expect(keys == ["_wpas_mess", "_wpas_skip_publicize_111"])
    }

    @Test("isDisabled handles supported metadata value shapes")
    func isDisabledHandlesSupportedValueShapes() {
        #expect(SocialSharingMetadata.isDisabled("1"))
        #expect(SocialSharingMetadata.isDisabled(true))
        #expect(!SocialSharingMetadata.isDisabled(false))
        #expect(SocialSharingMetadata.isDisabled(NSNumber(value: true)))
        #expect(!SocialSharingMetadata.isDisabled(NSNumber(value: false)))
        #expect(!SocialSharingMetadata.isDisabled(nil))
    }
}
