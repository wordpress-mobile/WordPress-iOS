public struct JetpackThreatFixResponse: Decodable {
    public let success: Bool
    public let threats: [JetpackThreatFixStatus]

    public let isFixingThreats: Bool

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decode(Bool.self, forKey: .success)

        let statusDict = try container.decode([String: [String: String]].self, forKey: .threats)
        var statusArray: [JetpackThreatFixStatus] = []

        for (threatId, status) in statusDict {
            guard let id = Int(threatId), let statusValue = status["status"] else {
                throw ResponseError.decodingFailure
            }

            let fixStatus = JetpackThreatFixStatus(with: id, status: statusValue)
            statusArray.append(fixStatus)
        }

        isFixingThreats = statusArray.filter { $0.status == .inProgress }.count > 0
        threats = statusArray
    }

    /// Returns true the fixing status is complete, and all threats are no longer in progress
    public var finished: Bool {
        return inProgress.count <= 0
    }

    /// Returns all the fixed threats
    public var fixed: [JetpackThreatFixStatus] {
        return threats.filter { $0.status == .fixed }
    }

    /// Returns all the in progress threats
    public var inProgress: [JetpackThreatFixStatus] {
        return threats.filter { $0.status == .inProgress }
    }

    private enum CodingKeys: String, CodingKey {
        case success = "ok", threats
    }

    enum ResponseError: Error {
        case decodingFailure
    }
}

public struct JetpackThreatFixStatus {
    public enum ThreatFixStatus: String, Decodable, UnknownCaseRepresentable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case fixed

        case unknown
        static let unknownCase: Self = .unknown
    }

    public let threatId: Int
    public let status: ThreatFixStatus

    public var threat: JetpackScanThreat?

    public init(with threatId: Int, status: String) {
        self.threatId = threatId
        self.status = ThreatFixStatus(rawValue: status)
    }

    public init(with threat: JetpackScanThreat, status: ThreatFixStatus = .inProgress) {
        self.threat = threat
        self.threatId = threat.id
        self.status = status
    }
}
