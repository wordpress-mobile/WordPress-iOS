import Foundation

public struct FeatureFlag {
    public let title: String
    public let value: Bool

    public init(title: String, value: Bool) {
        self.title = title
        self.value = value
    }
}

// Codable Conformance is used to create mock objects in testing
extension FeatureFlag: Codable {

    struct DynamicKey: CodingKey {
        var stringValue: String
        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        try container.encode(self.value, forKey: DynamicKey(stringValue: self.title))
    }
}

/// Comparable Conformance is used to compare objects in testing, and to provide stable `FeatureFlagList` ordering
extension FeatureFlag: Comparable {
    public static func < (lhs: FeatureFlag, rhs: FeatureFlag) -> Bool {
        lhs.title < rhs.title
    }
}

public typealias FeatureFlagList = [FeatureFlag]

extension FeatureFlagList {
    public var dictionaryValue: [String: Bool] {
        self.reduce(into: [:]) {
            $0[$1.title] = $1.value
        }
    }
}
