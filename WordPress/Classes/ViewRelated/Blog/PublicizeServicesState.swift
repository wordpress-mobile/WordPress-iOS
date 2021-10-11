import Foundation

@objc class PublicizeServicesState: NSObject {
    private var connections = Set<PublicizeConnection>() {
        didSet {
            print(connections, connections.count)
        }
    }

    @objc func addConnections(_ connections: [PublicizeConnection]) {
        connections.forEach { self.connections.insert($0) }
    }
}
