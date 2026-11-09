import Testing
import UIKit

@testable import WordPress

@Suite("Age requirement with a sign-in in progress")
@MainActor
struct AgeRequirementSignInRaceTests {
    @Test("Enforcement uses the sign-in state when the result arrives, not when the check started")
    func enforcesCurrentState() async {
        var signedIn = false
        let service = GatedAgeRangeService()
        let enforcer = AgeRequirementEnforcerRecorder {
            AgeRequirementUserState(wpComSignedIn: signedIn, selfHostedSiteCount: 0)
        }
        let coordinator = makeCoordinator(service: service, enforcer: enforcer)
        let anchor = AgeRequirementAnchor()

        let check = Task { await coordinator.checkIfNeeded(anchor: anchor.viewController) }
        await service.waitForRequest()
        signedIn = true // A sign-in finishes while the result is pending.
        service.respond(with: .sharing(lowerBound: 5))
        await check.value

        #expect(enforcer.enforcedStates == [.init(wpComSignedIn: true, selfHostedSiteCount: 0)])
    }

    @Test("Undoing a sign-in does nothing when not restricted")
    func undoWhenAllowed() async {
        let enforcer = AgeRequirementEnforcerRecorder { .init(wpComSignedIn: true, selfHostedSiteCount: 0) }
        let coordinator = makeCoordinator(service: GatedAgeRangeService(), enforcer: enforcer)

        #expect(await !coordinator.undoSignInIfRestricted(from: UIViewController()))
        #expect(enforcer.enforcedStates.isEmpty)
    }

    @Test("Undoing a sign-in after restriction enforces again with the saved account")
    func undoWhenRestricted() async {
        var signedIn = false
        let service = GatedAgeRangeService()
        let enforcer = AgeRequirementEnforcerRecorder {
            AgeRequirementUserState(wpComSignedIn: signedIn, selfHostedSiteCount: 0)
        }
        let coordinator = makeCoordinator(service: service, enforcer: enforcer)
        let anchor = AgeRequirementAnchor()

        let check = Task { await coordinator.checkIfNeeded(anchor: anchor.viewController) }
        await service.waitForRequest()
        service.respond(with: .sharing(lowerBound: 5))
        await check.value

        signedIn = true // The in-progress sign-in then saves its account.
        #expect(await coordinator.undoSignInIfRestricted(from: UIViewController()))
        #expect(
            enforcer.enforcedStates == [
                .init(wpComSignedIn: false, selfHostedSiteCount: 0),
                .init(wpComSignedIn: true, selfHostedSiteCount: 0)
            ]
        )
    }

    private func makeCoordinator(
        service: GatedAgeRangeService,
        enforcer: AgeRequirementEnforcerRecorder
    ) -> AgeRequirementCoordinator {
        AgeRequirementCoordinator(
            service: service,
            enforcer: enforcer,
            analyticsTracker: AgeRequirementAnalyticsTrackerNoop(),
            isSupported: true
        )
    }
}
