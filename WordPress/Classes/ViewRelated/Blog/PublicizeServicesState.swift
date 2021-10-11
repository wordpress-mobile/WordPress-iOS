import Foundation

@objc class PublicizeServicesState: NSObject {
    private var connections = Set<PublicizeConnection>()

    @objc func addInitialConnections(_ connections: [PublicizeConnection]) {
        connections.forEach { self.connections.insert($0) }
    }

    @objc func hasAddedNewConnectionTo(_ connections: [PublicizeConnection]) -> Bool {
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
