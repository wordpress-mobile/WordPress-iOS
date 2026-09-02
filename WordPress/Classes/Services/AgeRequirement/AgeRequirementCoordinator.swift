import UIKit
import WordPressShared
import WordPressUI

enum AgeRequirementNotCheckedReason: String, Equatable {
    case flagOff = "flag_off"
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
    /// Returns `true` and presents the restriction alert from `viewController` when the process is age restricted.
    @discardableResult func refuseSignInIfRestricted(from viewController: UIViewController) -> Bool
}

@MainActor
final class AgeRequirementCoordinator: AgeRequirementAccessControlling {
    static let shared = AgeRequirementCoordinator()

    private let service: AgeRangeServiceProtocol
    private let enforcer: AgeRequirementEnforcing
    private let analyticsTracker: AgeRequirementAnalyticsTracking
    private let isFeatureEnabled: () -> Bool
    private let isSupported: Bool

    private var didCheck = false
    private(set) var isRestricted = false

    convenience init() {
        self.init(
            service: AppleAgeRangeService(),
            enforcer: AgeRequirementEnforcer(),
            analyticsTracker: AgeRequirementAnalyticsTracker(),
            isFeatureEnabled: { RemoteFeatureFlag.ageRequirementCompliance.enabled() },
            isSupported: AgeRequirementCoordinator.isSupportedOS
        )
    }

    init(
        service: AgeRangeServiceProtocol,
        enforcer: AgeRequirementEnforcing,
        analyticsTracker: AgeRequirementAnalyticsTracking,
        isFeatureEnabled: @escaping () -> Bool,
        isSupported: Bool
    ) {
        self.service = service
        self.enforcer = enforcer
        self.analyticsTracker = analyticsTracker
        self.isFeatureEnabled = isFeatureEnabled
        self.isSupported = isSupported
    }

    func checkIfNeeded(anchor: UIViewController?) async {
        guard !didCheck else {
            return
        }
        didCheck = true

        let userState = enforcer.userState

        guard isFeatureEnabled() else {
            track(.notChecked(.flagOff), userState: userState)
            return
        }
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
                let presenter = await enforcer.enforceRestriction(userState: userState)
                let hadAccountOrSites = userState.wpComSignedIn || userState.selfHostedSiteCount > 0
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
