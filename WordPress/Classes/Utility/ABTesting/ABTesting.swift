import Foundation

enum Variation: Equatable {
    case control
    case treatment
    case other(String)
    case unknown
}

/// A protocol that defines a A/B Testing provider
///
protocol ABTesting {

    /// Refresh the assigned experiments
    func refresh(completion: (() -> Void)?)

    /// Return an experiment variation
    func experiment(_ name: String) -> Variation
}
