public struct JetpackScan: Decodable {
    public enum JetpackScanState: String, Decodable, UnknownCaseRepresentable {
        case idle
        case scanning
        case unavailable
        case provisioning

        // Internal states that don't come from the server

        // The scan will be in this state when its in the process of fixing any fixable threats
        case fixingThreats

        case unknown
        static let unknownCase: Self = .unknown
    }

    /// Whether the scan feature is available or not
    public var isEnabled: Bool {
        return (state != .unavailable) && (state != .unknown)
    }

    /// The state of the current scan
    public var state: JetpackScanState

    /// If a scan is in an unavailable state, this will return the reason
    public var reason: String?

    /// If there is a scan in progress, this will return its status
    public var current: JetpackScanStatus?

    /// Scan Status for the most recent scan
    /// This will be nil if there is currently a scan taking place
    public var mostRecent: JetpackScanStatus?

    /// An array of the current threats
    /// During a scan this will return the previous scans threats
    public var threats: [JetpackScanThreat]?

    /// A limited representation of the users credientals for each role
    public var credentials: [JetpackScanCredentials]?

    /// Internal var that doesn't come from the server
    /// An array of the threats being fixed current
    public var threatFixStatus: [JetpackThreatFixStatus]?

    // MARK: - Private: Decodable
    private enum CodingKeys: String, CodingKey {
        case mostRecent, state, reason, current, threats, credentials
    }
}

// MARK: - JetpackScanStatus
public struct JetpackScanStatus: Decodable {
    public var isInitial: Bool

    /// The date the scan started
    public var startDate: Date?

    /// The progress of the scan from 0 - 100
    public var progress: Int

    /// How long the scan took / is taking
    public var duration: TimeInterval?

    /// If there was an error finishing the scan
    /// This will only be available for past scans
    public var didFail: Bool?

    private enum CodingKeys: String, CodingKey {
        case startDate = "timestamp", didFail = "error"
        case duration, progress, isInitial
    }
}
