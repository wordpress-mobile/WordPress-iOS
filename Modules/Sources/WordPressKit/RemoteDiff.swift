import Foundation

/// RemoteDiff model
public struct RemoteDiff: Codable {
    /// Revision id from the content has been changed
    public var fromRevisionId: Int

    /// Current revision id
    public var toRevisionId: Int

    /// Model for the diff values
    public var values: RemoteDiffValues

    /// Mapping keys
    private enum CodingKeys: String, CodingKey {
        case fromRevisionId = "from"
        case toRevisionId = "to"
        case values = "diff"
    }

    // MARK: - Decode protocol

    public init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)

        fromRevisionId = (try? data.decode(Int.self, forKey: .fromRevisionId)) ?? 0
        toRevisionId = (try? data.decode(Int.self, forKey: .toRevisionId)) ?? 0
        values = try data.decode(RemoteDiffValues.self, forKey: .values)
    }
}

/// RemoteDiffValues model
public struct RemoteDiffValues: Codable {
    /// Model for the diff totals operations
    public var totals: RemoteDiffTotals?

    /// Title diffs array
    public var titleDiffs: [RemoteDiffValue]

    /// Content diffs array
    public var contentDiffs: [RemoteDiffValue]

    /// Mapping keys
    private enum CodingKeys: String, CodingKey {
        case titleDiffs = "post_title"
        case contentDiffs = "post_content"
        case totals
    }
}

/// RemoteDiffTotals model
public struct RemoteDiffTotals: Codable {
    /// Total of additional operations
    public var totalAdditions: Int

    /// Total of deletions operations
    public var totalDeletions: Int

    /// Mapping keys
    private enum CodingKeys: String, CodingKey {
        case totalAdditions = "add"
        case totalDeletions = "del"
    }

    // MARK: - Decode protocol

    public init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)

        totalAdditions = (try? data.decode(Int.self, forKey: .totalAdditions)) ?? 0
        totalDeletions = (try? data.decode(Int.self, forKey: .totalDeletions)) ?? 0
    }
}

/// RemoteDiffOperation enumeration
///
/// - add: Addition
/// - copy: Copy
/// - del: Deletion
/// - unknown: Default value
public enum RemoteDiffOperation: String, Codable {
    case add
    case copy
    case del
    case unknown
}

/// DiffValue
public struct RemoteDiffValue: Codable {
    /// Diff operation
    public var operation: RemoteDiffOperation

    /// Diff value
    public var value: String?

    /// Mapping keys
    private enum CodingKeys: String, CodingKey {
        case operation = "op"
        case value
    }

    // MARK: - Decode protocol

    public init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)

        operation = (try? data.decode(RemoteDiffOperation.self, forKey: .operation)) ?? .unknown
        value = try? data.decode(String.self, forKey: .value)
    }
}
