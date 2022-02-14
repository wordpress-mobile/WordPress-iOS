import AutomatticTracks

enum ABTest: String, CaseIterable {
    case unknown = "unknown"
    case landInTheEditorPhase1 = "wpios_land_in_the_editor_phase1_v3"

    /// Returns a variation for the given experiment
    var variation: Variation {
        return ExPlat.shared?.experiment(self.rawValue) ?? .control
    }
}

extension ABTest {
    /// Start the AB Testing platform if any experiment exists
    ///
    static func start() {
        guard ABTest.allCases.count > 1, AccountHelper.isLoggedIn else {
            return
        }

        let experimentNames = ABTest.allCases.filter { $0 != .unknown }.map { $0.rawValue }
        ExPlat.shared?.register(experiments: experimentNames)

        ExPlat.shared?.refresh()
    }
}
