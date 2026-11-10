import SVProgressHUD
import UIKit
import WordPressShared
import WordPressUI

enum AgeRequirementNotCheckedReason: String, Equatable {
    case osUnsupported = "os_unsupported"
    case noAnchor = "no_anchor"
}

enum AgeRequirementCheckOutcome: Equatable {
    case allowed
    case restricted
    case declined
    case unavailable
    case error
    case notChecked(AgeRequirementNotCheckedReason)
}

struct AgeRequirementUserState: Equatable {
    let wpComSignedIn: Bool
    let selfHostedSiteCount: Int
}

@MainActor
protocol AgeRequirementEnforcing: AnyObject {
    var userState: AgeRequirementUserState { get }
    /// Signs out and removes local sites. Returns the view controller to present the restriction alert from.
    func enforceRestriction(userState: AgeRequirementUserState) async -> UIViewController?
}

@MainActor
protocol AgeRequirementAccessControlling: AnyObject {
    /// Waits for the age check before a sign-in starts. Starts the check, anchored on `viewController`, if it hasn't
    /// started yet. Gives up after a timeout, and doesn't wait again once a wait has timed out.
    func waitForCheck(from viewController: UIViewController) async

    /// Returns `true` and presents the restriction alert from `viewController` when the process is age restricted.
    @discardableResult func refuseSignInIfRestricted(from viewController: UIViewController) -> Bool

    /// Call after a sign-in has saved its account or site. When the process became age restricted while the sign-in
    /// was saving (possible only after `waitForCheck(from:)` timed out), signs out, removes local sites, presents the
    /// restriction alert and returns `true`.
    func undoSignInIfRestricted(from viewController: UIViewController) async -> Bool
}

@MainActor
final class AgeRequirementCoordinator: AgeRequirementAccessControlling {
    static let shared = AgeRequirementCoordinator()

    private let service: AgeRangeServiceProtocol
    private let enforcer: AgeRequirementEnforcing
    private let analyticsTracker: AgeRequirementAnalyticsTracking
    private let isSupported: Bool
    private let signInWaitTimeout: Duration

    private var check: Task<Void, Never>?
    private var didTimeOutWaiting = false
    private(set) var isRestricted = false
    private var enforcement: Task<UIViewController?, Never>?

    convenience init() {
        self.init(
            service: AppleAgeRangeService(),
            enforcer: AgeRequirementEnforcer(),
            analyticsTracker: AgeRequirementAnalyticsTracker(),
            isSupported: AgeRequirementCoordinator.isSupportedOS
        )
    }

    init(
        service: AgeRangeServiceProtocol,
        enforcer: AgeRequirementEnforcing,
        analyticsTracker: AgeRequirementAnalyticsTracking,
        isSupported: Bool,
        signInWaitTimeout: Duration = .seconds(10)
    ) {
        self.service = service
        self.enforcer = enforcer
        self.analyticsTracker = analyticsTracker
        self.isSupported = isSupported
        self.signInWaitTimeout = signInWaitTimeout
    }

    /// Runs the check once per process. Later calls wait for the first one.
    func checkIfNeeded(anchor: UIViewController?) async {
        await startCheckIfNeeded(anchor: anchor).value
    }

    func waitForCheck(from viewController: UIViewController) async {
        let check = startCheckIfNeeded(anchor: viewController)
        guard !didTimeOutWaiting else {
            return
        }

        let waiter = CheckWaiter()
        let showsProgress = Task {
            try await Task.sleep(for: .milliseconds(300))
            Self.showProgress()
        }
        let finished = await waiter.wait(
            for: check,
            timeout: signInWaitTimeout
        )
        showsProgress.cancel()
        Self.dismissProgress()

        if !finished {
            didTimeOutWaiting = true
        }
    }

    private func startCheckIfNeeded(anchor: UIViewController?) -> Task<Void, Never> {
        if let check {
            return check
        }
        let check = Task { await runCheck(anchor: anchor) }
        self.check = check
        return check
    }

    private func runCheck(anchor: UIViewController?) async {
        let userState = enforcer.userState

        guard isSupported else {
            track(.notChecked(.osUnsupported), userState: userState)
            return
        }

        do {
            guard try await service.isEligible() else {
                return
            }
            guard let anchor, anchor.viewIfLoaded?.window != nil else {
                track(.notChecked(.noAnchor), userState: userState)
                return
            }

            switch try await service.requestAgeRange(in: anchor) {
            case .sharing(let lowerBound) where (lowerBound ?? 0) >= 13:
                track(.allowed, userState: userState)
            case .sharing:
                isRestricted = true
                // Read the state again: a sign-in may have finished while the result was pending.
                let currentState = enforcer.userState
                let presenter = await enforce()
                let hadAccountOrSites = currentState.wpComSignedIn || currentState.selfHostedSiteCount > 0
                presentRestrictionAlert(
                    from: presenter,
                    message: hadAccountOrSites ? Strings.signedOutMessage : Strings.signedOutUserMessage
                )
                track(.restricted, userState: userState)
            case .declined:
                track(.declined, userState: userState)
            }
        } catch .unavailable {
            track(.unavailable, userState: userState)
        } catch {
            track(.error, userState: userState)
        }
    }

    @discardableResult
    func refuseSignInIfRestricted(from viewController: UIViewController) -> Bool {
        guard isRestricted else {
            return false
        }
        presentRestrictionAlert(from: viewController, message: Strings.signedOutUserMessage)
        return true
    }

    func undoSignInIfRestricted(from viewController: UIViewController) async -> Bool {
        guard isRestricted else {
            return false
        }
        let presenter = await enforce()
        presentRestrictionAlert(from: presenter ?? viewController, message: Strings.signedOutUserMessage)
        return true
    }

    /// Runs one enforcement at a time, each against the sign-in state at the moment it starts.
    private func enforce() async -> UIViewController? {
        let previous = enforcement
        let task = Task { [enforcer] in
            _ = await previous?.value
            return await enforcer.enforceRestriction(userState: enforcer.userState)
        }
        enforcement = task
        return await task.value
    }

    private func track(_ outcome: AgeRequirementCheckOutcome, userState: AgeRequirementUserState) {
        analyticsTracker.track(outcome, userState: userState)
    }

    private func presentRestrictionAlert(from viewController: UIViewController?, message: String) {
        guard let presenter = viewController?.topmostPresentedViewController else {
            return
        }
        if let alert = presenter as? UIAlertController, alert.title == Strings.title {
            return
        }

        let alert = UIAlertController(title: Strings.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: SharedStrings.Button.ok, style: .default))
        presenter.present(alert, animated: true)
    }

    // Synchronous wrappers: from async code, `SVProgressHUD.dismiss()` binds to an async overload that can hang.
    private static func showProgress() {
        SVProgressHUD.show()
    }

    private static func dismissProgress() {
        SVProgressHUD.dismiss()
    }

    private static var isSupportedOS: Bool {
        if #available(iOS 26.2, *) {
            return true
        }
        return false
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "ageRequirement.restrictionAlert.title",
        value: "Age requirement not met",
        comment: "Title of an alert explaining that the person does not meet the app's minimum age requirement"
    )
    static let signedOutMessage = NSLocalizedString(
        "ageRequirement.restrictionAlert.signedOutMessage",
        value:
            "This app requires users to be 13 or older. Your Apple Account reports an age under 13, so you've been signed out and your sites have been removed from this device.",
        comment: "Message shown after age restriction enforcement signs a person out and removes their sites"
    )
    static let signedOutUserMessage = NSLocalizedString(
        "ageRequirement.restrictionAlert.signedOutUserMessage",
        value:
            "This app requires users to be 13 or older. Your Apple Account reports an age under 13, so you can't sign in.",
        comment: "Message shown when an age-restricted person tries to sign in"
    )
}

/// Waits for a task to finish, or for a timeout, whichever comes first, without cancelling the task.
@MainActor
private final class CheckWaiter {
    private var continuation: CheckedContinuation<Bool, Never>?

    /// Returns `true` if `task` finished before the timeout.
    func wait(for task: Task<Void, Never>, timeout: Duration) async -> Bool {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            Task {
                await task.value
                self.resume(returning: true)
            }
            Task {
                try? await Task.sleep(for: timeout)
                self.resume(returning: false)
            }
        }
    }

    private func resume(returning finished: Bool) {
        continuation?.resume(returning: finished)
        continuation = nil
    }
}
