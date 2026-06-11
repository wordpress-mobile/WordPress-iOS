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
            ["key": "_wpas_skip_444", "value": "0"],
            ["key": "unrelated", "value": "value"]
        ])

        let draft = PostSocialSharingDraft(socialMetadata: container)

        #expect(draft.customMessage == "Hello")
        #expect(!draft.isEnabled(connection: makeConnection(id: "111", keyringID: "881")))
        #expect(draft.isEnabled(connection: makeConnection(id: "222", keyringID: "882")))
        #expect(draft.isEnabled(connection: makeConnection(id: "999", keyringID: "883")))
        // Only truthy legacy rows mark their suffix as disabled.
        #expect(draft.legacyDisabledKeys == ["333"])
    }

    @Test("legacy rows disable connections by keyring ID and service name")
    func legacyRowsDisableConnectionsByKeyringAndService() {
        let container = PostMetadataContainer(metadata: [
            ["key": "_wpas_skip_333", "value": "1"],
            ["key": "_wpas_skip_mastodon", "value": "1"]
        ])
        let draft = PostSocialSharingDraft(socialMetadata: container)

        let byKeyring = makeConnection(id: "1", keyringID: "333")
        let sameKeyring = makeConnection(id: "2", keyringID: "333")
        let byService = makeConnection(id: "3", keyringID: "555", service: "mastodon")
        let unaffected = makeConnection(id: "4", keyringID: "777")

        #expect(!draft.isEnabled(connection: byKeyring))
        // A keyring-keyed row covers every connection on that keyring.
        #expect(!draft.isEnabled(connection: sameKeyring))
        #expect(!draft.isEnabled(connection: byService))
        #expect(draft.isEnabled(connection: unaffected))
    }

    @Test("legacy row wins over an enabled connection-keyed row")
    func legacyRowWinsOverEnabledConnectionRow() {
        // The backend ORs all skip schemes, so `_wpas_skip_publicize_1 = 0`
        // cannot re-enable a connection whose legacy row is still truthy.
        let container = PostMetadataContainer(metadata: [
            ["key": "_wpas_skip_publicize_1", "value": "0"],
            ["key": "_wpas_skip_333", "value": "1"]
        ])
        let draft = PostSocialSharingDraft(socialMetadata: container)

        #expect(!draft.isEnabled(connection: makeConnection(id: "1", keyringID: "333")))
    }

    @Test("enabling clears legacy keys and pins same-keyring siblings")
    func enablingClearsLegacyKeysAndPinsSiblings() {
        let container = PostMetadataContainer(metadata: [
            ["key": "_wpas_skip_333", "value": "1"]
        ])
        var draft = PostSocialSharingDraft(socialMetadata: container)

        let football = makeConnection(id: "1", keyringID: "333")
        let basketball = makeConnection(id: "2", keyringID: "333")
        let mastodon = makeConnection(id: "3", keyringID: "555", service: "mastodon")
        let all = [football, basketball, mastodon]

        draft.setEnabled(true, for: football, availableConnections: all)

        #expect(draft.isEnabled(connection: football))
        // The sibling sharing the keyring must stay off after the shared
        // legacy key is cleared.
        #expect(!draft.isEnabled(connection: basketball))
        #expect(draft.isEnabled(connection: mastodon))
        #expect(draft.legacyDisabledKeys.isEmpty)
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

    @Test("serialize zeroes legacy rows cleared by re-enabling")
    func serializeZeroesClearedLegacyRows() {
        var container = PostMetadataContainer(metadata: [
            ["key": "_wpas_skip_333", "value": "1"],
            ["key": "_wpas_skip_777", "value": "1"]
        ])
        var draft = PostSocialSharingDraft(socialMetadata: container)
        let connection = makeConnection(id: "1", keyringID: "333")

        draft.setEnabled(true, for: connection, availableConnections: [connection])
        draft.applySocialMetadata(to: &container)

        #expect(container.getString(for: "_wpas_skip_publicize_1") == "0")
        // The cleared legacy row must be zeroed; the backend ORs all skip
        // schemes, so leaving it truthy would keep suppressing the share.
        #expect(container.getString(for: "_wpas_skip_333") == "0")
        // A legacy row the user did not clear stays untouched, even when its
        // keyring matches no known connection.
        #expect(container.getString(for: "_wpas_skip_777") == "1")
    }

    @Test("serialize leaves legacy rows alone without user changes")
    func serializeLeavesLegacyRowsAloneWithoutUserChanges() {
        var container = PostMetadataContainer(metadata: [
            ["key": "_wpas_skip_333", "value": "1"]
        ])
        let draft = PostSocialSharingDraft(socialMetadata: container)

        draft.applySocialMetadata(to: &container)

        #expect(container.getString(for: "_wpas_skip_333") == "1")
    }

    @Test("upload entries include publicize and legacy skip keys")
    func uploadEntriesIncludePublicizeAndLegacySkipKeys() {
        let container = PostMetadataContainer(metadata: [
            ["key": "_wpas_mess", "value": "Hello"],
            ["key": "_wpas_skip_publicize_111", "value": "1"],
            ["key": "_wpas_skip_222", "value": "1"],
            ["key": "_jetpack_newsletter_access", "value": "subscribers"],
            ["key": "unrelated", "value": "value"]
        ])

        let entries = SocialSharingMetadata.publicizeEntries(in: container)
        let keys = Set(entries.compactMap { $0["key"] as? String })

        #expect(keys == ["_wpas_mess", "_wpas_skip_publicize_111", "_wpas_skip_222"])
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

    private func makeConnection(
        id: String,
        keyringID: String?,
        service: String = "facebook"
    ) -> SocialConnection {
        SocialConnection(
            id: id,
            keyringConnectionID: keyringID,
            externalID: "external-\(id)",
            serviceName: service,
            serviceLabel: service.capitalized,
            displayName: "Connection \(id)",
            externalHandle: nil,
            profileLink: nil,
            profilePictureURL: nil,
            isShared: true,
            status: .ok
        )
    }
}
