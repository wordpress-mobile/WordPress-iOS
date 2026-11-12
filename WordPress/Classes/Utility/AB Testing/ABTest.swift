import AutomatticTracks
import BuildSettingsKit
import Foundation
import WordPressShared

/// ExPlat experiments.
///
/// Each raw value is the experiment's name in ExPlat, on the `wpios` platform that every app uses.
/// An experiment runs only in the apps listed in `apps`: other apps don't request its assignment,
/// and `variation` returns `.control` there.
enum ABTest: String, CaseIterable {
    case unknown = "unknown"

    /// The treatment shows a live Reader tab in the WordPress app instead of the Moved-to-Jetpack poster.
    case readerInWordPressApp = "wpios_reader_in_wordpress_app_v1"

    /// The apps that run this experiment.
    var apps: Set<AppBrand> {
        switch self {
        case .unknown: []
        case .readerInWordPressApp: [.wordpress]
        }
    }

    /// Returns a variation for the given experiment
    var variation: Variation {
        variation(in: BuildSettings.current.brand)
    }

    func variation(in app: AppBrand, exPlat: ABTesting? = ExPlat.shared) -> Variation {
        guard apps.contains(app) else {
            return .control
        }
        return exPlat?.experiment(rawValue) ?? .control
    }

    /// Flag indicating whether the experiment's variation is treament or not.
    var isTreatmentVariation: Bool {
        switch variation {
        case .treatment, .customTreatment: return true
        case .control: return false
        }
    }
}

/// The part of `ExPlat` that fetches assignments. Tests may use their own.
protocol ExperimentAssigning: AnyObject {
    func register(experiments experimentNames: [String])
    func refresh(completion: (() -> Void)?)
}

extension ExPlat: ExperimentAssigning {}

extension ABTest {
    /// The experiments that run in `app`.
    static func experiments(in app: AppBrand) -> [ABTest] {
        allCases.filter { $0.apps.contains(app) }
    }

    /// The `UserDefaults` keys where `ExPlat` stores assignments (`ExPlat.swift` in
    /// Automattic-Tracks-iOS). ExPlat has no API to clear them.
    static let exPlatStorageKeys = ["ab-testing-assignments", "ab-testing-ttl-date", "ab-testing-enrolled-experiments"]

    /// Completions waiting for the fetch in flight, or `nil` when none is running. Main queue only.
    private static var pendingCompletions: [() -> Void]?

    /// How many times `reset()` has run. Main queue only.
    private static var resetCount = 0

    /// Registers the current app's experiments and fetches their assignments for the signed-in
    /// WordPress.com account.
    ///
    /// Nothing is requested while signed out or after the user opts out of analytics. ExPlat
    /// prefers a stored anonymous assignment over the account's, so a signed-out request would let
    /// a returning user switch groups at their next sign-in.
    ///
    /// A call while a fetch is in flight joins it instead of starting another.
    ///
    /// - Parameter completion: Called on the main queue once the assignments are stored, or when
    ///   the request fails or isn't made.
    static func start(
        app: AppBrand = BuildSettings.current.brand,
        isDotComAvailable: Bool = AccountHelper.isDotcomAvailable(),
        hasOptedOutOfAnalytics: Bool = WPAppAnalytics.userHasOptedOut(),
        exPlat: ExperimentAssigning? = ExPlat.shared,
        userDefaults: UserDefaults = .standard,
        completion: (() -> Void)? = nil
    ) {
        wpAssert(Thread.isMainThread)
        let experimentNames = experiments(in: app).map(\.rawValue)
        guard !experimentNames.isEmpty, isDotComAvailable, !hasOptedOutOfAnalytics, let exPlat else {
            completion?()
            return
        }
        if pendingCompletions != nil {
            if let completion {
                pendingCompletions?.append(completion)
            }
            return
        }
        pendingCompletions = completion.map { [$0] } ?? []
        let resetCountAtStart = resetCount
        exPlat.register(experiments: experimentNames)
        exPlat.refresh {
            // `ExPlat.refresh` drops the answer if its `ExPlat` has been released by then, and Tracks
            // replaces `ExPlat.shared` whenever analytics metadata refreshes, which happens during the
            // account and site sync after launch. Keep this one alive until it has stored the answer.
            withExtendedLifetime(exPlat) {}
            DispatchQueue.main.async {
                // The answer belongs to an account that has signed out or opted out since.
                if resetCount != resetCountAtStart {
                    removeStoredAssignments(from: userDefaults)
                }
                let completions = pendingCompletions ?? []
                pendingCompletions = nil
                completions.forEach { $0() }
            }
        }
    }

    /// Forgets the registered experiments and every stored assignment, so the next account doesn't
    /// inherit them and ExPlat makes no more requests. A request started by `start()` that answers
    /// later is cleared too. Call it at sign-out and on analytics opt-out.
    static func reset(exPlat: ExperimentAssigning? = ExPlat.shared, userDefaults: UserDefaults = .standard) {
        wpAssert(Thread.isMainThread)
        resetCount += 1
        exPlat?.register(experiments: [])
        removeStoredAssignments(from: userDefaults)
    }

    private static func removeStoredAssignments(from userDefaults: UserDefaults) {
        for key in exPlatStorageKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
}

/// Lets Objective-C code reset the experiments.
@objc final class ABTestObjCBridge: NSObject {
    @objc static func resetExperiments() {
        ABTest.reset()
    }
}
