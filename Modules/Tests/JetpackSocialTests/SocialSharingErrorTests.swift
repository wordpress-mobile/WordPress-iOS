import Foundation
import Testing
@testable import JetpackSocial

@Suite("SocialSharingError")
struct SocialSharingErrorTests {
    @Test("every case produces a non-empty localized description")
    func everyCaseHasDescription() {
        let cases: [SocialSharingError] = [
            .network(NSError(domain: "t", code: 1)),
            .notAuthenticated,
            .connectionNotFound(id: "42"),
            .keyringNotFound(id: 99),
            .noKeyringForService(serviceLabel: "Mastodon"),
            .noPagesForFacebook,
            .decoding(NSError(domain: "t", code: 2)),
            .unknown(NSError(domain: "t", code: 3))
        ]

        for error in cases {
            let description = error.errorDescription ?? ""
            #expect(!description.isEmpty, "\(error) produced empty description")
        }
    }

    @Test("noPagesForFacebook exposes the Pages help URL")
    func noPagesForFacebookHasHelpURL() {
        let url = try! #require(SocialSharingError.noPagesForFacebook.helpURL)
        #expect(url.absoluteString.contains("publicize"))
        #expect(url.absoluteString.contains("facebook-pages"))
    }

    @Test("errors without dedicated help docs return nil helpURL")
    func otherErrorsHaveNoHelpURL() {
        #expect(SocialSharingError.notAuthenticated.helpURL == nil)
        #expect(SocialSharingError.noKeyringForService(serviceLabel: "Mastodon").helpURL == nil)
        #expect(SocialSharingError.network(NSError(domain: "t", code: 1)).helpURL == nil)
    }
}
