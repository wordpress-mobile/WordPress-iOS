import AutomatticTracks

// Experiments run only in Jetpack; `start()` is a no-op in the WordPress app.
enum ABTest: String, CaseIterable {
    case unknown = "unknown"
    case siteCreationShortFlow = "jpios_site_creation_short_flow_v1"

    /// Returns a variation for the given experiment
    var variation: Variation {
        variation(in: ExPlat.shared)
    }

    /// Flag indicating whether the experiment's variation is treament or not.
    var isTreatmentVariation: Bool {
        isTreatmentVariation(in: ExPlat.shared)
    }

    /// A person whose assignment has not arrived yet counts as control, so callers never wait on ExPlat.
    func variation(in abTesting: ABTesting?) -> Variation {
        abTesting?.experiment(rawValue) ?? .control
    }

    func isTreatmentVariation(in abTesting: ABTesting?) -> Bool {
        switch variation(in: abTesting) {
        case .treatment, .customTreatment: return true
        case .control: return false
        }
    }
}

extension ABTest {
    /// Start the AB Testing platform if any experiment exists
    ///
    static func start() {
        guard ABTest.allCases.count > 1,
              AccountHelper.isLoggedIn,
              AppConfiguration.isJetpack,
              let exPlat = ExPlat.shared
        else {
            return
        }
        let experimentNames = ABTest.allCases.filter { $0 != .unknown }.map { $0.rawValue }
        exPlat.register(experiments: experimentNames)
        exPlat.refresh()
    }
}
