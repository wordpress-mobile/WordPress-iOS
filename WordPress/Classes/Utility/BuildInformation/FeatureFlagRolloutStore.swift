// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol RolloutConfigurableFlag: CustomStringConvertible {
    var rolloutPercentage: Double? { get }
}
