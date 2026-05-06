import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import JetpackSocial

@Suite("SocialConnection mapping")
struct SocialConnectionTests {
    @Test("maps required wire fields")
    func mapsRequiredFields() {
        let wire = PublicizeConnectionResponse(
            connectionId: "123",
            displayName: "Tony Li",
            externalHandle: "@tony",
            externalId: "ext-42",
            profileLink: "https://example.com/tony",
            profilePicture: "https://example.com/tony.jpg",
            serviceLabel: "Mastodon",
            serviceName: "mastodon",
            shared: true,
            wpcomUserId: 0,
            id: "deprecated",
            username: "",
            profileDisplayName: "",
            global: false,
            status: "ok"
        )

        let model = SocialConnection(from: wire)

        #expect(model.id == "123")
        #expect(model.externalID == "ext-42")
        #expect(model.serviceName == "mastodon")
        #expect(model.serviceLabel == "Mastodon")
        #expect(model.displayName == "Tony Li")
        #expect(model.externalHandle == "@tony")
        #expect(model.profileLink == URL(string: "https://example.com/tony"))
        #expect(model.profilePictureURL == URL(string: "https://example.com/tony.jpg"))
        #expect(model.isShared)
        #expect(model.status == .ok)
    }

    @Test("empty display_name falls back to external_handle")
    func emptyDisplayNameFallsBackToHandle() {
        let wire = PublicizeConnectionResponse(
            connectionId: "1",
            displayName: "",
            externalHandle: "@tony@mastodon.social",
            externalId: "",
            profileLink: "",
            profilePicture: "",
            serviceLabel: "Mastodon",
            serviceName: "mastodon",
            shared: false,
            wpcomUserId: 0,
            id: "",
            username: "",
            profileDisplayName: "",
            global: false,
            status: nil
        )

        let model = SocialConnection(from: wire)
        #expect(model.displayName == "@tony@mastodon.social")
        #expect(model.externalHandle == "@tony@mastodon.social")
    }

    @Test("empty display_name and empty handle stays empty")
    func emptyDisplayNameAndHandleStaysEmpty() {
        let wire = PublicizeConnectionResponse(
            connectionId: "1",
            displayName: "",
            externalHandle: "",
            externalId: "",
            profileLink: "",
            profilePicture: "",
            serviceLabel: "x",
            serviceName: "x",
            shared: false,
            wpcomUserId: 0,
            id: "",
            username: "",
            profileDisplayName: "",
            global: false,
            status: nil
        )

        let model = SocialConnection(from: wire)
        #expect(model.displayName.isEmpty)
        #expect(model.externalHandle == nil)
    }

    @Test("empty external_handle becomes nil")
    func emptyExternalHandleBecomesNil() {
        let wire = PublicizeConnectionResponse(
            connectionId: "1",
            displayName: "x",
            externalHandle: "",
            externalId: "",
            profileLink: "",
            profilePicture: "",
            serviceLabel: "x",
            serviceName: "x",
            shared: false,
            wpcomUserId: 0,
            id: "",
            username: "",
            profileDisplayName: "",
            global: false,
            status: nil
        )

        let model = SocialConnection(from: wire)
        #expect(model.externalID.isEmpty)
        #expect(model.externalHandle == nil)
        #expect(model.profileLink == nil)
        #expect(model.profilePictureURL == nil)
        #expect(model.status == .unknown)
    }
}
