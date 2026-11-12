import AutomatticTracks
import BuildSettingsKit

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

extension ABTest {
    /// The experiments that run in `app`.
    static func experiments(in app: AppBrand) -> [ABTest] {
        allCases.filter { $0.apps.contains(app) }
    }

    /// Registers the current app's experiments and fetches their assignments.
    ///
    /// Signed-out users are assigned by their anonymous Tracks ID. After sign-in, Tracks sends that
    /// ID along with the account's token, so ExPlat keeps the group it assigned before sign-in.
    ///
    /// - Parameter completion: Called once the assignments are stored, or when the request fails
    ///   or isn't made. It may be called on a background queue.
    static func start(completion: (() -> Void)? = nil) {
        let experimentNames = experiments(in: BuildSettings.current.brand).map(\.rawValue)
        guard !experimentNames.isEmpty, let exPlat = ExPlat.shared else {
            completion?()
            return
        }
        exPlat.register(experiments: experimentNames)
        exPlat.refresh(completion: completion)
    }
}
