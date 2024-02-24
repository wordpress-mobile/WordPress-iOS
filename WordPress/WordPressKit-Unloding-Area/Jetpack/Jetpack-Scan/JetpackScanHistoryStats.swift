public struct JetpackScanHistoryStats: Decodable {
    public let scans: Int?
    public let threatsFound: Int?
    public let threatsResolved: Int?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        scans = Self.decode(in: container, forKey: .scans)
        threatsFound = Self.decode(in: container, forKey: .threatsFound)
        threatsResolved = Self.decode(in: container, forKey: .threatsResolved)
    }

    /// Special handling of the decoding since it could be a string or an int
    private static func decode(in container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        var intVal: Int?
        if let stringVal = try? container.decode(String.self, forKey: key) {
            intVal = Int(stringVal)
        } else if let val = try? container.decode(Int.self, forKey: key) {
            intVal = val
        }

        guard let value = intVal else {
            return nil
        }

        return value < 0 ? nil : value
    }

    private enum CodingKeys: String, CodingKey {
        case scans, threatsFound, threatsResolved
    }
}
