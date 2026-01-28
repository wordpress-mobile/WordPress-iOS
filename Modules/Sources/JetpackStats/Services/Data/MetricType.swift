import SwiftUI

/// Protocol defining the requirements for a metric type that can be displayed in stats views.
protocol MetricType: Identifiable, Hashable, Equatable, Sendable {
    var localizedTitle: String { get }
    var systemImage: String { get }
    var primaryColor: Color { get }
    var isHigherValueBetter: Bool { get }
    var aggregationStrategy: AggregationStrategy { get }

    /// Creates the appropriate value formatter for this metric type.
    func makeValueFormatter() -> any ValueFormatterProtocol
}

enum AggregationStrategy: Sendable {
    /// Simply sum the values for the given period.
    case sum
    /// Calculate the average value for the given period.
    case average
}
