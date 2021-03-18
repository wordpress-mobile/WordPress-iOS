import AutomatticTracks

enum ABTest: String, CaseIterable {
    case unknown = "unknown"
    case biasTest = "explat_test_aa_weekly_wpios_2021_week_06"

    /// Returns a variation for the given experiment
    var variation: Variation {
        return ExPlat.shared?.experiment(self.rawValue) ?? .control
    }
}

extension ABTest {
    /// Start the AB Testing platform if any experiment exists
    ///
    static func start() {
        guard ABTest.allCases.count > 1 else {
            return
        }

        ExPlat.shared?.refresh()
    }

    static func refreshIfNeeded() {
        guard ABTest.allCases.count > 1 else {
            return
        }

        ExPlat.shared?.refreshIfNeeded()
    }
}
