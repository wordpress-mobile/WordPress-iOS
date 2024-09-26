import Foundation

@objc final class PublicizeServicesState: NSObject {
    private var connections = Set<PublicizeConnection>()
}

// MARK: - Public Methods
@objc extension PublicizeServicesState {
    func addInitialConnections(_ connections: [PublicizeConnection]) {
        connections.forEach { self.connections.insert($0) }
    }

    func hasAddedNewConnectionTo(_ connections: [PublicizeConnection]) -> Bool {
        guard connections.count > 0 else {
            return false
        }

        if connections.count > self.connections.count {
            return true
        }

        for connection in connections where !self.connections.contains(connection) {
            return true
        }

        return false
    }
}
