import AutomatticTracks

enum ABTest: String, CaseIterable {
    case unknown = "unknown"

    /// Returns a variation for the given experiment
    var variation: Variation {
        return ExPlat.shared.experiment(self.rawValue)
    }
}

extension ABTest {
    /// Start the AB Testing platform if any experiment exists
    ///
    static func start() {
        guard ABTest.allCases.count > 1 else {
            return
        }

        ExPlat.shared.refreshIfNeeded()
    }
}
