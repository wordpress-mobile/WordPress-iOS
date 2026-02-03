import Foundation

public struct StatsDeviceItem: Decodable {
    public let name: String
    public let value: Double

    public init(name: String, value: Double) {
        self.name = name
        self.value = value
    }
}

public struct StatsDeviceTimeIntervalData: Decodable {
    public let items: [StatsDeviceItem]

    enum CodingKeys: String, CodingKey {
        case topValues = "top_values"
    }

    public init(items: [StatsDeviceItem]) {
        self.items = items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode top_values dictionary (Double handles both percentages and integer counts)
        let topValues = try container.decode([String: Double].self, forKey: .topValues)

        // Convert dictionary to array of items, sorted by value descending
        self.items = topValues.map { key, value in
            StatsDeviceItem(name: key, value: value)
        }.sorted { $0.value > $1.value }
    }
}
