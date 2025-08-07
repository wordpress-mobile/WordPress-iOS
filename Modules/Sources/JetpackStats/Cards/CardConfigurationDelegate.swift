import Foundation

enum MoveDirection {
    case up
    case down
    case top
    case bottom
}

@MainActor
protocol CardConfigurationDelegate: AnyObject {
    func saveConfiguration(for card: any TrafficCardViewModel)
    func deleteCard(_ card: any TrafficCardViewModel)
    func moveCard(_ card: any TrafficCardViewModel, direction: MoveDirection)
}
