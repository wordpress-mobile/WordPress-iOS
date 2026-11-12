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

    /// A request made by `start()` that hasn't answered yet.
    private final class Fetch {
        /// Keeps the `ExPlat` alive until the request answers. `ExPlat.refresh` drops the answer if
        /// its `ExPlat` has been released by then, and Tracks replaces `ExPlat.shared` whenever
        /// analytics metadata refreshes, which happens during the account and site sync after launch.
        let exPlat: ExperimentAssigning
        let generation: Int
        var completions: [() -> Void]

        init(exPlat: ExperimentAssigning, generation: Int, completions: [() -> Void]) {
            self.exPlat = exPlat
            self.generation = generation
            self.completions = completions
        }
    }

    /// The request in flight, or `nil` when none is running. Main queue only.
    private static var fetch: Fetch?

    /// Increases with every `reset()`, so a request can tell whether it belongs to an account that
    /// has signed out or opted out since. Main queue only.
    private static var generation = 0

    /// The generation whose answer is stored, if any. Main queue only.
    private static var storedGeneration: Int?

    /// Registers the current app's experiments and fetches their assignments for the signed-in
    /// WordPress.com account.
    ///
    /// Nothing is requested while signed out or after the user opts out of analytics. ExPlat
    /// prefers a stored anonymous assignment over the account's, so a signed-out request would let
    /// a returning user switch groups at their next sign-in.
    ///
    /// A call while a request is in flight joins it instead of starting another, unless `reset()`
    /// has run since that request started.
    ///
    /// - Parameter completion: Called on the main queue once the assignments are stored, or when
    ///   the request fails, isn't made, or is abandoned by `reset()`.
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
        if let fetch {
            if let completion {
                fetch.completions.append(completion)
            }
            return
        }
        let generationAtStart = generation
        fetch = Fetch(exPlat: exPlat, generation: generationAtStart, completions: completion.map { [$0] } ?? [])
        exPlat.register(experiments: experimentNames)
        // The closure must not hold the `ExPlat`: `reset()` releases it by dropping `fetch`, so a
        // request from a signed-out account can't store its answer.
        exPlat.refresh {
            DispatchQueue.main.async {
                didAnswer(generation: generationAtStart, userDefaults: userDefaults)
            }
        }
    }

    private static func didAnswer(generation answerGeneration: Int, userDefaults: UserDefaults) {
        guard answerGeneration == generation else {
            // An answer to a request that `reset()` abandoned. Its `ExPlat` stores it only if it
            // is still alive, which happens when it is still `ExPlat.shared` (for example after an
            // opt-out). Clear it unless a newer request has already stored its own answer.
            if storedGeneration != generation {
                removeStoredAssignments(from: userDefaults)
            }
            return
        }
        storedGeneration = answerGeneration
        let completions = fetch?.completions ?? []
        fetch = nil
        completions.forEach { $0() }
    }

    /// Forgets the registered experiments and every stored assignment, so the next account doesn't
    /// inherit them and ExPlat makes no more requests. A request in flight is abandoned: its
    /// `ExPlat` is released unless it is still `ExPlat.shared`, its waiting completions run now,
    /// and an answer that still arrives is cleared. Call it at sign-out and on analytics opt-out.
    static func reset(exPlat: ExperimentAssigning? = ExPlat.shared, userDefaults: UserDefaults = .standard) {
        wpAssert(Thread.isMainThread)
        generation += 1
        storedGeneration = nil
        let abandoned = fetch
        fetch = nil
        exPlat?.register(experiments: [])
        abandoned?.exPlat.register(experiments: [])
        removeStoredAssignments(from: userDefaults)
        abandoned?.completions.forEach { $0() }
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
