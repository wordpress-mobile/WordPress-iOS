import Foundation

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

    public init(backupPoint: Date, downloadID: Int, rewindID: String, startedAt: Date, progress: Int?, downloadCount: Int?, url: String?, validUntil: Date?) {
        self.backupPoint = backupPoint
        self.downloadID = downloadID
        self.rewindID = rewindID
        self.startedAt = startedAt
        self.progress = progress
        self.downloadCount = downloadCount
        self.url = url
        self.validUntil = validUntil
    }
}
