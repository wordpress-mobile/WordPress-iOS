import Testing
import UIKit

@testable import WordPress

@Suite("Age requirement coordinator")
@MainActor
struct AgeRequirementCoordinatorTests {
    @Test("A disabled flag records a skipped check")
    func flagOff() async {
        let harness = Harness(flagEnabled: false)

        await harness.check()

        #expect(harness.service.eligibilityCallCount == 0)
        #expect(harness.tracker.events.map(\.outcome) == [.notChecked(.flagOff)])
        #expect(!harness.coordinator.isRestricted)
    }

    @Test("An unsupported OS records a skipped check")
    func unsupportedOS() async {
        let harness = Harness(isSupported: false)

        await harness.check()

        #expect(harness.service.eligibilityCallCount == 0)
        #expect(harness.tracker.events.map(\.outcome) == [.notChecked(.osUnsupported)])
    }

    @Test("An ineligible region produces no event")
    func ineligibleRegion() async {
        let harness = Harness(eligible: false)

        await harness.check()

        #expect(harness.service.requestCallCount == 0)
        #expect(harness.tracker.events.isEmpty)
    }

    @Test(
        "Service failures fail open",
        arguments: [
            (AgeRangeServiceError.unavailable, AgeRequirementCheckOutcome.unavailable),
            (.unknown, .error)
        ]
    )
    func serviceFailures(error: AgeRangeServiceError, expected: AgeRequirementCheckOutcome) async {
        let eligibility = Harness(eligibilityError: error)
        await eligibility.check()
        #expect(eligibility.tracker.events.map(\.outcome) == [expected])

        let request = Harness(requestError: error)
        await request.check()
        #expect(request.tracker.events.map(\.outcome) == [expected])
        #expect(!request.coordinator.isRestricted)
    }

    @Test("An anchor that is not on screen records a skipped check")
    func missingAnchor() async {
        let harness = Harness()

        await harness.coordinator.checkIfNeeded(anchor: UIViewController())

        #expect(harness.service.eligibilityCallCount == 1)
        #expect(harness.service.requestCallCount == 0)
        #expect(harness.tracker.events.map(\.outcome) == [.notChecked(.noAnchor)])
    }

    @Test(
        "Non-restricted service results fail open",
        arguments: [
            (AgeRangeServiceResult.sharing(lowerBound: 13), AgeRequirementCheckOutcome.allowed),
            (.sharing(lowerBound: 18), .allowed),
            (.declined, .declined)
        ]
    )
    func allowedResults(result: AgeRangeServiceResult, expected: AgeRequirementCheckOutcome) async {
        let harness = Harness(result: result)

        await harness.check()

        #expect(harness.enforcer.enforcementCount == 0)
        #expect(harness.tracker.events.map(\.outcome) == [expected])
        #expect(!harness.coordinator.isRestricted)
    }

    @Test(
        "An affirmative under-13 result enforces and records the original context",
        arguments: [
            AgeRequirementUserState(wpComSignedIn: true, selfHostedSiteCount: 0),
            AgeRequirementUserState(wpComSignedIn: false, selfHostedSiteCount: 2),
            AgeRequirementUserState(wpComSignedIn: false, selfHostedSiteCount: 0)
        ]
    )
    func restrictedResult(userState: AgeRequirementUserState) async {
        let harness = Harness(result: .sharing(lowerBound: nil), userState: userState)

        await harness.check()

        #expect(harness.enforcer.enforcementCount == 1)
        #expect(harness.coordinator.isRestricted)
        #expect(harness.tracker.events == [.init(outcome: .restricted, userState: userState)])
        #expect(harness.recorder.values == ["enforce", "track"])
    }

    @Test("A second trigger does not repeat the check")
    func checksOnce() async {
        let harness = Harness()

        await harness.check()
        await harness.check()

        #expect(harness.service.eligibilityCallCount == 1)
        #expect(harness.service.requestCallCount == 1)
        #expect(harness.tracker.events.count == 1)
    }

    @Test("Sign-in is refused only after restriction")
    func signInRefusal() async {
        let allowed = Harness()
        #expect(!allowed.coordinator.refuseSignInIfRestricted(from: UIViewController()))

        let restricted = Harness(result: .sharing(lowerBound: nil))
        await restricted.check()
        #expect(restricted.coordinator.refuseSignInIfRestricted(from: UIViewController()))
    }

    @Test("Analytics maps the outcome and check-time context")
    func analyticsProperties() throws {
        AnalyticsEventTrackingSpy.reset()
        let tracker = AgeRequirementAnalyticsTracker(tracker: AnalyticsEventTrackingSpy.self)

        tracker.track(.notChecked(.noAnchor), userState: .init(wpComSignedIn: true, selfHostedSiteCount: 2))

        let event = try #require(AnalyticsEventTrackingSpy.trackedEvents.first)
        #expect(event.name == "age_requirement_check")
        #expect(
            event.properties == [
                "outcome": "not_checked",
                "reason": "no_anchor",
                "logged_out": "false",
                "wpcom_signed_in": "true",
                "self_hosted_site_count": "2"
            ]
        )
    }
}

@MainActor
private struct Harness {
    let recorder = Recorder()
    let service: AgeRangeServiceFake
    let enforcer: AgeRequirementEnforcerSpy
    let tracker: AgeRequirementAnalyticsTrackerSpy
    let coordinator: AgeRequirementCoordinator

    /// An on-screen view controller for the age range prompt.
    private let window: UIWindow
    private let anchor = UIViewController()

    init(
        flagEnabled: Bool = true,
        isSupported: Bool = true,
        eligible: Bool = true,
        eligibilityError: AgeRangeServiceError? = nil,
        result: AgeRangeServiceResult = .sharing(lowerBound: 13),
        requestError: AgeRangeServiceError? = nil,
        userState: AgeRequirementUserState = .init(wpComSignedIn: true, selfHostedSiteCount: 2)
    ) {
        let service = AgeRangeServiceFake(
            eligible: eligible,
            eligibilityError: eligibilityError,
            result: result,
            requestError: requestError
        )
        let enforcer = AgeRequirementEnforcerSpy(userState: userState, recorder: recorder)
        let tracker = AgeRequirementAnalyticsTrackerSpy(recorder: recorder)
        self.service = service
        self.enforcer = enforcer
        self.tracker = tracker
        self.coordinator = AgeRequirementCoordinator(
            service: service,
            enforcer: enforcer,
            analyticsTracker: tracker,
            isFeatureEnabled: { flagEnabled },
            isSupported: isSupported
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = anchor
        window.isHidden = false
    }

    func check() async {
        await coordinator.checkIfNeeded(anchor: anchor)
    }
}

@MainActor
private final class AgeRangeServiceFake: AgeRangeServiceProtocol {
    let eligible: Bool
    let eligibilityError: AgeRangeServiceError?
    let result: AgeRangeServiceResult
    let requestError: AgeRangeServiceError?
    private(set) var eligibilityCallCount = 0
    private(set) var requestCallCount = 0

    init(
        eligible: Bool,
        eligibilityError: AgeRangeServiceError?,
        result: AgeRangeServiceResult,
        requestError: AgeRangeServiceError?
    ) {
        self.eligible = eligible
        self.eligibilityError = eligibilityError
        self.result = result
        self.requestError = requestError
    }

    func isEligible() async throws(AgeRangeServiceError) -> Bool {
        eligibilityCallCount += 1
        if let eligibilityError {
            throw eligibilityError
        }
        return eligible
    }

    func requestAgeRange(
        in viewController: UIViewController
    ) async throws(AgeRangeServiceError) -> AgeRangeServiceResult {
        requestCallCount += 1
        if let requestError {
            throw requestError
        }
        return result
    }
}

@MainActor
private final class AgeRequirementEnforcerSpy: AgeRequirementEnforcing {
    let userState: AgeRequirementUserState
    private let recorder: Recorder
    private(set) var enforcementCount = 0

    init(userState: AgeRequirementUserState, recorder: Recorder) {
        self.userState = userState
        self.recorder = recorder
    }

    func enforceRestriction(userState: AgeRequirementUserState) async -> UIViewController? {
        enforcementCount += 1
        recorder.values.append("enforce")
        return nil
    }
}

@MainActor
private final class AgeRequirementAnalyticsTrackerSpy: AgeRequirementAnalyticsTracking {
    struct Event: Equatable {
        let outcome: AgeRequirementCheckOutcome
        let userState: AgeRequirementUserState
    }

    private let recorder: Recorder
    private(set) var events: [Event] = []

    init(recorder: Recorder) {
        self.recorder = recorder
    }

    func track(_ outcome: AgeRequirementCheckOutcome, userState: AgeRequirementUserState) {
        events.append(.init(outcome: outcome, userState: userState))
        recorder.values.append("track")
    }
}

@MainActor
private final class Recorder {
    var values: [String] = []
}
