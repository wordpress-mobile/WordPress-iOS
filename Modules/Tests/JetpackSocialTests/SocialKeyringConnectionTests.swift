import Foundation
import Testing
import WordPressAPI
@testable import JetpackSocial

@Suite("SocialKeyringConnection mapping")
struct SocialKeyringConnectionTests {
    @Test("maps keyring with additional users")
    func mapsKeyringWithAdditionalUsers() {
        let additional = KeyringExternalUser(
            externalId: "page-1",
            externalName: "My Page",
            externalProfilePicture: "https://example.com/page.jpg",
            externalDescription: "A description",
            externalCategory: nil
        )

        let wire = KeyringConnectionResponse(
            id: 42,
            userId: 1,
            service: "facebook",
            label: "Facebook",
            externalId: "fb-user",
            externalName: "Tony",
            externalDisplay: "Tony Li",
            externalProfilePicture: "https://example.com/me.jpg",
            status: "ok",
            refreshUrl: "",
            additionalExternalUsers: [additional]
        )

        let model = SocialKeyringConnection(from: wire)

        #expect(model.id == 42)
        #expect(model.service == "facebook")
        #expect(model.externalID == "fb-user")
        #expect(model.externalDisplay == "Tony Li")
        #expect(model.additionalExternalUsers.count == 1)
        #expect(model.additionalExternalUsers.first?.id == "page-1")
        #expect(model.additionalExternalUsers.first?.name == "My Page")
        #expect(model.status == .ok)
    }

    @Test("empty external_display falls back to external_name")
    func emptyExternalDisplayFallsBackToExternalName() {
        let wire = KeyringConnectionResponse(
            id: 7,
            userId: 1,
            service: "mastodon",
            label: nil,
            externalId: "ext",
            externalName: "tony",
            externalDisplay: "",
            externalProfilePicture: nil,
            status: "ok",
            refreshUrl: "",
            additionalExternalUsers: []
        )
        let model = SocialKeyringConnection(from: wire)
        #expect(model.externalDisplay == "tony")
    }

    @Test("handles missing optional fields")
    func handlesMissingOptionals() {
        let wire = KeyringConnectionResponse(
            id: 1,
            userId: 1,
            service: "x",
            label: nil,
            externalId: "",
            externalName: "",
            externalDisplay: "",
            externalProfilePicture: nil,
            status: "",
            refreshUrl: "",
            additionalExternalUsers: []
        )
        let model = SocialKeyringConnection(from: wire)
        #expect(model.externalProfilePictureURL == nil)
        #expect(model.additionalExternalUsers.isEmpty)
        #expect(model.status == .unknown)
    }
}
