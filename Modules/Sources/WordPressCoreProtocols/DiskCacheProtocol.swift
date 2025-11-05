import Foundation

public protocol DiskCacheProtocol: Actor {
    func read<T>(
        _ type: T.Type,
        forKey key: String,
        notOlderThan interval: TimeInterval?
    ) throws -> T? where T: Decodable

    func store<T>(_ value: T, forKey key: String) throws where T: Encodable

    func remove(key: String) throws

    func removeAll(progress: (@Sendable (CacheDeletionProgress) async throws -> Void)?) async throws

    func count() async throws -> Int

    func diskUsage() async throws -> DiskCacheUsage
}

public struct CacheDeletionProgress: Sendable, Equatable {
    public let filesDeleted: Int
    public let totalFileCount: Int

    public var progress: Double {
        if filesDeleted > 0 && totalFileCount > 0 {
            return Double(filesDeleted) / Double(totalFileCount)
        }

        return 0
    }

    public init(filesDeleted: Int, totalFileCount: Int) {
        self.filesDeleted = filesDeleted
        self.totalFileCount = totalFileCount
    }
}

public struct DiskCacheUsage: Sendable, Equatable {
    public let fileCount: Int
    public let byteCount: Int64

    public init(fileCount: Int, byteCount: Int64) {
        self.fileCount = fileCount
        self.byteCount = byteCount
    }

    public var diskUsage: Measurement<UnitInformationStorage> {
        Measurement(value: Double(byteCount), unit: .bytes)
    }

    public var formattedDiskUsage: String {
        return diskUsage.formatted(.byteCount(style: .file, allowedUnits: [.mb, .gb], spellsOutZero: true))
    }

    public var isEmpty: Bool {
        fileCount == 0
    }
}
