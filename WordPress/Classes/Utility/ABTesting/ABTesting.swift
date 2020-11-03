import Foundation

/// A protocol that defines a A/B Testing provider
///
protocol ABTesting {

    /// Refresh the assigned experiments
    func refresh()
}
