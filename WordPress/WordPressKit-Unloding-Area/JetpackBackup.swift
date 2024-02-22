public struct JetpackBackup: Decodable {

    // Common
    public let backupPoint: Date
    public let downloadID: Int
    public let rewindID: String
    public let startedAt: Date

    // Prepare backup
    public let progress: Int?

    // Get backup status
    public let downloadCount: Int?
    public let url: String?
    public let validUntil: Date?

    private enum CodingKeys: String, CodingKey {
        case backupPoint
        case downloadID = "downloadId"
        case rewindID = "rewindId"
        case startedAt
        case progress
        case downloadCount
        case url
        case validUntil
    }
}
