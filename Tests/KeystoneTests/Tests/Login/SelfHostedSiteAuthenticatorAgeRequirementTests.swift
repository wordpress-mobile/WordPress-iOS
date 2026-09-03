import Testing
import UIKit

@testable import WordPress

@Suite("Self-hosted sign-in age requirement")
@MainActor
struct SelfHostedSiteAuthenticatorAgeRequirementTests {
    @Test("A restricted sign-in stops before site discovery")
    func refusesAtEntry() async {
        let accessController = AgeRequirementAccessControllerFake(refusalResponses: [true])
        let authenticator = SelfHostedSiteAuthenticator(ageRequirementController: accessController)

        do {
            _ = try await authenticator.signIn(
                site: "https://example.com",
                from: UIViewController(),
                context: .default
            )
            Issue.record("Expected age-restricted sign-in to stop")
        } catch SelfHostedSiteAuthenticator.SignInError.ageRestricted {
            #expect(accessController.refusalCount == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
