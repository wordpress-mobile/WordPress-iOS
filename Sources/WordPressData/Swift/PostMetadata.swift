import Foundation
import WordPressKit
import WordPressShared

/// A convenience struct that provides CRUD operations on post metadata.
///
/// ## WordPress Metadata Overview
///
/// WordPress stores custom metadata as key-value pairs associated with posts.
/// Each metadata item contains a string key, a value (which can be any
/// JSON-serializable type), and an optional ID for database tracking.
///
/// ## Expected Format
///
/// Metadata is stored as a JSON array of dictionaries, where each dictionary represents one
/// metadata item:
///
/// ```json
/// [
///   {
///     "key": "_jetpack_newsletter_access",
///     "value": "subscribers",
///     "id": "123"
///   },
///   {
///     "key": "custom_field",
///     "value": "some value"
///   }
/// ]
/// ```
public struct PostMetadata {
    public struct Key: ExpressibleByStringLiteral, Hashable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }
    }

    enum Error: Swift.Error {
        case invalidData
    }

    // Raw JSON dictionaries, keyed by metadata key
    private var items: [Key: [String: Any]] = [:]

    /// Returns all metadata as a dictionary (alias for allItems)
    public var values: [[String: Any]] {
        Array(items.values)
    }

    /// Initialized metadata with the given post.
    public init(_ post: AbstractPost) {
        if let data = post.rawMetadata {
            do {
                let metadata = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
                self = PostMetadata(metadata: metadata)
            } catch {
                wpAssertionFailure("Failed to decode metadata JSON", userInfo: ["error": error.localizedDescription])
                self = PostMetadata()
            }
        } else {
            self = PostMetadata()
        }
    }

    /// Initialize with raw metadata Data (non-throwing version for backward compatibility)
    /// If the data is invalid, creates an empty PostMetadata
    ///
    /// - Parameter data: The JSON data containing metadata array
    public init(data: Data) throws {
        let metadata = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = metadata as? [[String: Any]] else {
            throw Error.invalidData
        }
        self = PostMetadata(metadata: dictionary)
    }

    /// Initialize with raw metadata array (same format as JSON data)
    /// - Parameter metadata: Array of metadata dictionaries with "key", "value", and optional "id"
    public init(metadata: [[String: Any]] = []) {
        for item in metadata {
            if let key = item["key"] as? String {
                self.items[Key(rawValue: key)] = item
            }
        }
    }

    // MARK: - Encoding

    /// Encodes the metadata back to Data for storage in rawMetadata
    /// - Returns: JSON Data representation of the metadata, or nil if empty
    public func encode() throws -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: Array(items.values), options: [])
        } catch {
            wpAssertionFailure("Failed to encode metadata to JSON", userInfo: ["error": error.localizedDescription])
            throw error
        }
    }

    // MARK: - CRUD

    /// Retrieves a metadata value by key with generic type casting
    /// - Parameters:
    ///   - expectedType: The expected type of the value
    ///   - key: The metadata key to search for
    /// - Returns: The value cast to the specified type if found and compatible, nil otherwise
    public func getValue<T>(_ expectedType: T.Type, forKey key: Key) -> T? {
        guard let dict = items[key], let value = dict["value"] else { return nil }
        guard let value = value as? T else {
            wpAssertionFailure("unexpected value", userInfo: [
                "key": key.rawValue,
                "actual_type": String(describing: expectedType),
                "expected_type": String(describing: type(of: value))
            ])
            return nil
        }
        return value
    }

    /// Retrieves a metadata value by key as String (convenience method)
    /// - Parameter key: The metadata key to search for
    /// - Returns: The value as String if found and convertible, nil otherwise
    public func getString(for key: Key) -> String? {
        getValue(String.self, forKey: key)
    }

    /// Sets or updates a metadata item with any JSON-compatible value
    /// - Parameters:
    ///   - value: The metadata value (must be JSON-compatible)
    ///   - key: The metadata key
    ///   - id: Optional metadata ID
    public mutating func setValue(_ value: Any, for key: Key, id: String? = nil) {
        var dict: [String: Any] = [
            "key": key.rawValue,
            "value": value
        ]
        // Preserve existing ID if not provided
        if let id {
            dict["id"] = id
        } else if let existingDict = items[key], let existingID = existingDict["id"] {
            dict["id"] = existingID
        }
        guard JSONSerialization.isValidJSONObject(dict) else {
            return wpAssertionFailure("invalid value", userInfo: ["type": String(describing: type(of: value))])
        }
        items[key] = dict
    }

    /// Removes a metadata item by key
    /// - Parameter key: The metadata key to remove
    /// - Returns: True if the item was found and removed, false otherwise
    @discardableResult
    public mutating func removeValue(for key: Key) -> Bool {
        items.removeValue(forKey: key) != nil
    }

    /// Clears all metadata
    public mutating func clear() {
        items.removeAll()
    }

    /// Returns the complete dictionary entry for the given key.
    ///
    /// - Parameter key: The metadata key to retrieve
    /// - Returns: The complete metadata dictionary containing "key", "value", and optional "id", or nil if not found
    public func entry(forKey key: Key) -> [String: Any]? {
        return items[key]
    }
}

// MARK: - PostMetadata (Jetpack)

extension PostMetadata.Key {
    /// Jetpack Newsletter access level metadata key
    public static let jetpackNewsletterAccess: PostMetadata.Key = "_jetpack_newsletter_access"
}

extension PostMetadata {
    /// Gets or sets the Jetpack Newsletter access level as a PostAccessLevel enum
    public var accessLevel: JetpackPostAccessLevel? {
        get {
            guard let value = getString(for: .jetpackNewsletterAccess) else { return nil }
            return JetpackPostAccessLevel(rawValue: value)
        }
        set {
            if let newValue {
                setValue(newValue.rawValue, for: .jetpackNewsletterAccess)
            } else {
                removeValue(for: .jetpackNewsletterAccess)
            }
        }
    }
}

/// Valid access levels for Jetpack Newsletter
public enum JetpackPostAccessLevel: String, CaseIterable, Hashable, Codable {
    case everybody = "everybody"
    case subscribers = "subscribers"
    case paidSubscribers = "paid_subscribers"
}
