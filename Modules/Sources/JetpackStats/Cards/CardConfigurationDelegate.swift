import Foundation

@MainActor
protocol CardConfigurationDelegate: AnyObject {
    func saveConfiguration(for card: any TrafficCardViewModel)
    func deleteCard(_ card: any TrafficCardViewModel)
}