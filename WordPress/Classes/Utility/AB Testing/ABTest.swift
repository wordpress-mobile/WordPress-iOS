import AutomatticTracks

// Attention: AB test is available only for WPiOS
// Jetpack is not supported
enum ABTest: String, CaseIterable {
    case unknown = "unknown"
    case siteCreationDomainPurchasing = "jpios_site_creation_domain_purchasing_v1"

    /// Returns a variation for the given experiment
    var variation: Variation {
        return ExPlat.shared?.experiment(self.rawValue) ?? .control
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
