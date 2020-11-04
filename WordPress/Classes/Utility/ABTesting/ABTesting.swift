import Foundation

/// A protocol that defines a A/B Testing provider
///
protocol ABTesting {

    /// Refresh the assigned experiments
    func refresh(completion: (() -> Void)?)

    /// Return an experiment variation
    func experiment(_ name: String) -> String?
}
