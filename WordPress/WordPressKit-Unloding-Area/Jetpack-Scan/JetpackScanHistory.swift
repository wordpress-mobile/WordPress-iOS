public struct JetpackScanHistory: Decodable {
    public let threats: [JetpackScanThreat]
    public let lifetimeStats: JetpackScanHistoryStats
}
