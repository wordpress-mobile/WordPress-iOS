import UIKit

@testable import WordPress

/// An eligible age range service whose `requestAgeRange` waits until the test calls `respond(with:)`.
///
/// Use it to make the age result arrive at an exact point in another flow, such as while a sign-in is saving.
@MainActor
final class GatedAgeRangeService: AgeRangeServiceProtocol {
    private var continuation: CheckedContinuation<AgeRangeServiceResult, Never>?

    /// `true` once `requestAgeRange` is waiting for `respond(with:)`.
    var isWaiting: Bool { continuation != nil }

    func isEligible() async throws(AgeRangeServiceError) -> Bool {
        true
    }

    func requestAgeRange(
        in viewController: UIViewController
    ) async throws(AgeRangeServiceError) -> AgeRangeServiceResult {
        await withCheckedContinuation { continuation = $0 }
    }

    /// Waits until `requestAgeRange` has been called.
    func waitForRequest() async {
        while !isWaiting {
            await Task.yield()
        }
    }

    func respond(with result: AgeRangeServiceResult) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}

/// Records each enforcement and the sign-in state it was given, without touching app data or UI.
@MainActor
final class AgeRequirementEnforcerRecorder: AgeRequirementEnforcing {
    private let userStateProvider: () -> AgeRequirementUserState
    private(set) var enforcedStates: [AgeRequirementUserState] = []

    init(userStateProvider: @escaping () -> AgeRequirementUserState) {
        self.userStateProvider = userStateProvider
    }

    var userState: AgeRequirementUserState {
        userStateProvider()
    }

    func enforceRestriction(userState: AgeRequirementUserState) async -> UIViewController? {
        enforcedStates.append(userState)
        return nil
    }
}

@MainActor
struct AgeRequirementAnalyticsTrackerNoop: AgeRequirementAnalyticsTracking {
    func track(_ outcome: AgeRequirementCheckOutcome, userState: AgeRequirementUserState) {}
}

/// A window with an on-screen view controller, for the age range prompt anchor.
@MainActor
final class AgeRequirementAnchor {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    let viewController = UIViewController()

    init() {
        window.rootViewController = viewController
        window.isHidden = false
    }
}
