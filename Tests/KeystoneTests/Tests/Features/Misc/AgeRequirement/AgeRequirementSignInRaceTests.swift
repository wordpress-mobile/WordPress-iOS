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

    @Test("Waiting before sign-in returns once a pending check finishes")
    func waitReturnsWhenCheckFinishes() async {
        let service = GatedAgeRangeService()
        let coordinator = makeCoordinator(
            service: service,
            enforcer: AgeRequirementEnforcerRecorder { .init(wpComSignedIn: false, selfHostedSiteCount: 0) },
            signInWaitTimeout: .seconds(60)
        )
        let anchor = AgeRequirementAnchor()

        let check = Task { await coordinator.checkIfNeeded(anchor: anchor.viewController) }
        await service.waitForRequest()

        var didFinishWaiting = false
        let wait = Task {
            await coordinator.waitForCheck(from: anchor.viewController)
            didFinishWaiting = true
        }
        for _ in 0..<20 { await Task.yield() }
        #expect(!didFinishWaiting)

        service.respond(with: .sharing(lowerBound: 5))
        await wait.value
        await check.value
        #expect(didFinishWaiting)
        #expect(coordinator.isRestricted)
    }

    @Test("Waiting before sign-in starts the check when it hasn't started")
    func waitStartsCheck() async {
        let service = GatedAgeRangeService()
        let coordinator = makeCoordinator(
            service: service,
            enforcer: AgeRequirementEnforcerRecorder { .init(wpComSignedIn: false, selfHostedSiteCount: 0) },
            signInWaitTimeout: .seconds(60)
        )
        let anchor = AgeRequirementAnchor()

        let wait = Task { await coordinator.waitForCheck(from: anchor.viewController) }
        await service.waitForRequest()
        service.respond(with: .sharing(lowerBound: 18))
        await wait.value

        #expect(!coordinator.isRestricted)
    }

    @Test("Waiting before sign-in gives up after the timeout, and only waits once")
    func waitTimesOut() async {
        let service = GatedAgeRangeService()
        let coordinator = makeCoordinator(
            service: service,
            enforcer: AgeRequirementEnforcerRecorder { .init(wpComSignedIn: false, selfHostedSiteCount: 0) },
            signInWaitTimeout: .milliseconds(100)
        )
        let anchor = AgeRequirementAnchor()

        let clock = ContinuousClock()
        let first = await clock.measure { await coordinator.waitForCheck(from: anchor.viewController) }
        let second = await clock.measure { await coordinator.waitForCheck(from: anchor.viewController) }

        #expect(service.isWaiting) // The check itself keeps running.
        #expect(first >= .milliseconds(100))
        #expect(second < .milliseconds(100))
        service.respond(with: .declined)
    }

    private func makeCoordinator(
        service: GatedAgeRangeService,
        enforcer: AgeRequirementEnforcerRecorder,
        signInWaitTimeout: Duration = .seconds(10)
    ) -> AgeRequirementCoordinator {
        AgeRequirementCoordinator(
            service: service,
            enforcer: enforcer,
            analyticsTracker: AgeRequirementAnalyticsTrackerNoop(),
            isSupported: true,
            signInWaitTimeout: signInWaitTimeout
        )
    }
}
