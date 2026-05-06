import Foundation
import Testing
import WordPressAPI
@testable import JetpackSocial

@Suite("SocialService mapping")
struct SocialServiceTests {
    @Test("maps wire fields")
    func mapsFields() {
        let wire = PublicizeServiceResponse(
            id: "mastodon",
            description: "Share to your Mastodon timeline",
            label: "Mastodon",
            status: "ok",
            supports: PublicizeServiceSupports(additionalUsers: false, additionalUsersOnly: false),
            url: "https://mastodon.example"
        )

        let model = SocialService(from: wire)

        #expect(model.id == "mastodon")
        #expect(model.label == "Mastodon")
        #expect(model.description == "Share to your Mastodon timeline")
        #expect(!model.supportsAdditionalUsers)
        #expect(!model.additionalUsersOnly)
        #expect(model.isActive)
        #expect(model.connectURL == URL(string: "https://mastodon.example"))
    }

    @Test("maps additionalUsersOnly from supports")
    func mapsAdditionalUsersOnly() {
        let wire = PublicizeServiceResponse(
            id: "facebook",
            description: "",
            label: "Facebook",
            status: "ok",
            supports: PublicizeServiceSupports(additionalUsers: true, additionalUsersOnly: true),
            url: ""
        )
        let model = SocialService(from: wire)
        #expect(model.additionalUsersOnly)
        #expect(model.supportsAdditionalUsers)
    }

    @Test("empty url maps to nil connectURL")
    func emptyURLMapsToNil() {
        let wire = PublicizeServiceResponse(
            id: "s",
            description: "",
            label: "s",
            status: "ok",
            supports: PublicizeServiceSupports(additionalUsers: false, additionalUsersOnly: false),
            url: ""
        )
        let model = SocialService(from: wire)
        #expect(model.connectURL == nil)
    }

    @Test("non-ok status maps to inactive")
    func nonOkStatusIsInactive() {
        let wire = PublicizeServiceResponse(
            id: "s",
            description: "",
            label: "s",
            status: "deprecated",
            supports: PublicizeServiceSupports(additionalUsers: true, additionalUsersOnly: false),
            url: ""
        )
        let model = SocialService(from: wire)
        #expect(!model.isActive)
        #expect(model.supportsAdditionalUsers)
    }
}
