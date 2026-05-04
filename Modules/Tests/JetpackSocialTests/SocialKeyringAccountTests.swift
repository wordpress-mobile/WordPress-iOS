import Foundation
import Testing
@testable import JetpackSocial

@Suite("SocialKeyringAccount")
struct SocialKeyringAccountTests {
    private func makeKeyring(
        id: Int64 = 1,
        service: String = "mastodon",
        externalID: String = "primary-ext",
        externalDisplay: String = "@primary",
        additional: [AdditionalExternalUser] = []
    ) -> SocialKeyringConnection {
        SocialKeyringConnection(
            id: id,
            service: service,
            externalID: externalID,
            externalName: "primary",
            externalDisplay: externalDisplay,
            externalProfilePictureURL: nil,
            additionalExternalUsers: additional,
            status: .ok
        )
    }

    @Test("flatten produces one account for a keyring with no additional users")
    func flattenSingleAccount() {
        let keyring = makeKeyring()
        let accounts = SocialKeyringAccount.flatten([keyring])
        #expect(accounts.count == 1)
        let account = try! #require(accounts.first)
        #expect(account.externalUserID == nil)
        #expect(account.name == "@primary")
        #expect(account.id == "1:primary:primary-ext")
        #expect(account.externalIDForMatching == "primary-ext")
    }

    @Test("flatten produces primary + additional user rows")
    func flattenMultipleAccounts() {
        let page = AdditionalExternalUser(id: "page-1", name: "My Page", description: nil, profilePictureURL: nil)
        let keyring = makeKeyring(additional: [page])
        let accounts = SocialKeyringAccount.flatten([keyring])
        #expect(accounts.count == 2)
        #expect(accounts[0].externalUserID == nil)
        #expect(accounts[0].name == "@primary")
        #expect(accounts[0].externalIDForMatching == "primary-ext")
        #expect(accounts[1].externalUserID == "page-1")
        #expect(accounts[1].name == "My Page")
        #expect(accounts[1].id == "1:user:page-1")
        #expect(accounts[1].externalIDForMatching == "page-1")
    }

    @Test("flatten preserves order across multiple keyrings")
    func flattenMultipleKeyrings() {
        let a = makeKeyring(id: 10, service: "bluesky", externalID: "bs-a", externalDisplay: "@a")
        let b = makeKeyring(id: 20, service: "bluesky", externalID: "bs-b", externalDisplay: "@b")
        let accounts = SocialKeyringAccount.flatten([a, b])
        #expect(accounts.map(\.id) == ["10:primary:bs-a", "20:primary:bs-b"])
    }

    @Test("id is composite of keyring id and external user id for primary vs additional")
    func compositeIDFormat() {
        let additional = AdditionalExternalUser(id: "x-1", name: "X", description: nil, profilePictureURL: nil)
        let keyring = makeKeyring(id: 42, externalID: "prim", additional: [additional])
        let accounts = SocialKeyringAccount.flatten([keyring])
        #expect(accounts[0].id == "42:primary:prim")
        #expect(accounts[1].id == "42:user:x-1")
    }
}
